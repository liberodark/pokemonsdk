module Battle
  class Move
    # Thrash Move
    class Thrash < BasicWithSuccessfulEffect
      private

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity
      def on_move_failure(user, targets, reason)
        # @type [Effects::ForcedNextMove::Disturbable]
        effect = user.effects.get(:forced_next_move)
        effect.disturbed = true if effect.is_a?(Effects::ForcedNextMove::Disturbable)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        # @type [Effects::ForcedNextMove::Disturbable]
        effect = user.effects.get(:forced_next_move)
        if effect.is_a?(Effects::ForcedNextMove::Disturbable)
          if !effect.disturbed && logic.status_change_handler.status_appliable?(:confusion, user)
            logic.status_change_handler.status_change(:confusion, user)
          end
        else
          effect&.kill
          user.effects.add(Effects::ForcedNextMove::Disturbable.new(logic, user, self, actual_targets, rand(1..2)))
        end
      end
    end

    Move.register(:s_thrash, Thrash)
  end
end
