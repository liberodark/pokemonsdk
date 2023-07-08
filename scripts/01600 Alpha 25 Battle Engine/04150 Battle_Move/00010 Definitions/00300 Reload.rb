module Battle
  class Move
    class Reload < BasicWithSuccessfulEffect
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return false if user.effects.has?(:force_next_move_base)

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.effects.add(Effects::ForceNextMoveBase.new(@logic, user, self, actual_targets, turn_count))
      end

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity, :pp
      def on_move_failure(user, targets, reason)
        @scene.display_message_and_wait(parse_text_with_pokemon(19, 851, user)) if reason == :usable_by_user && user.effects.has?(:force_next_move_base)
      end

      # Return the number of turns the effect works
      # @return Integer
      def turn_count
        return 2
      end
    end
    Move.register(:s_reload, Reload)
  end
end
