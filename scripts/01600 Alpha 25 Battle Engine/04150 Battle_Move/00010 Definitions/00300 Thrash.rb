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
        return if user.has_ability?(:dancer) && user.ability_effect.activated?

        # @type [Effects::ForceNextMoveBase]
        effect = user.effects.get(:force_next_move_base)
        return if effect.nil?
        return effect.kill unless effect.triggered?

        logic.status_change_handler.status_change_with_process(:confusion, user, nil, self) unless user.confused?
      end

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return !(user.has_ability?(:dancer) && user.ability_effect.activated?)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        # @type [Effects::ForceNextMoveBase]
        effect = user.effects.get(:force_next_move_base)
        if effect
          logic.status_change_handler.status_change_with_process(:confusion, user, nil, self) if effect.triggered? && !user.confused?
        else
          user.effects.add(Effects::ForceNextMoveBase.new(logic, user, self, actual_targets, turn_count))
        end
      end

      # Return the number of turns the effect works
      # @return Integer
      def turn_count
        return @logic.generic_rng.rand(2..3)
      end
    end
    Move.register(:s_thrash, Thrash)
    Move.register(:s_outrage, Thrash)
  end
end
