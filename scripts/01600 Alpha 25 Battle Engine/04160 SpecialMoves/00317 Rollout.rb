module Battle
  class Move
    # Move that is used during 5 turn and get more powerfull until it gets interrupted
    class Rollout < BasicWithSuccessfulEffect
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        # @type [Effects::Rollout]
        rollout_effect = user.effects.get(:rollout)
        mod = rollout_effect.successive_uses if rollout_effect
        mod = (mod || 0) + 1 if user.move_history.any? { |move| move.db_symbol == :defense_curl }
        return super * 2 ** (mod || 0)
      end

      private

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity
      def on_move_failure(user, targets, reason)
        user.effects.get(:rollout)&.kill
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        # @type [Effects::Rollout]
        rollout_effect = user.effects.get(:rollout)
        return rollout_effect.increase if rollout_effect

        effect = Effects::Rollout.new(logic, user, self, actual_targets, 5)
        user.effects.replace(effect, &:force_next_move?)
        effect.increase
      end
    end

    Move.register(:s_rollout, Rollout)
  end
end
