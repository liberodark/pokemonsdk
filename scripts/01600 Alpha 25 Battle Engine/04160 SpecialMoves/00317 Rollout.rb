module Battle
  class Move
    # Move that is used during 5 turn and get more powerfull until it gets interrupted
    class Rollout < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        # @type [Effects::ForcedNextMove::Rollout]
        rollout_effect = user.effects.get(:forced_next_move)
        if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
          mod = rollout_effect.successive_uses + 1
          mod += 1 if user.move_history.any? { |move| move.db_symbol == :defense_curl }
        else
          mod = 1
        end
        return power * mod
      end

      private

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity
      def on_move_failure(user, targets, reason)
        # @type [Effects::ForcedNextMove::Rollout]
        rollout_effect = user.effects.get(:forced_next_move)
        rollout_effect.successive_uses = 1 if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
      end

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        # @type [Effects::ForcedNextMove::Rollout]
        rollout_effect = user.effects.get(:forced_next_move)
        if rollout_effect.is_a?(Effects::ForcedNextMove::Rollout)
          rollout_effect.successive_uses += 1
        else
          rollout_effect&.kill
          user.effects.add(Effects::ForcedNextMove::Rollout.new(logic, user, self, actual_targets))
        end
      end
    end

    Move.register(:s_rollout, Rollout)
  end
end
