module Battle
  class Move
    # Move that switches the user's position with its ally
    class AllySwitch < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if @logic.adjacent_allies_of(user).count != 1 # Fails if there are no allies or two allies (center of triple battle)
          show_usage_failure(user)
          return false
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, _)
        ally = @logic.adjacent_allies_of(user).first
        @logic.switch_battlers(user, ally)
        scene.visual.show_switch_form_animation(ally)
        scene.visual.show_switch_form_animation(user)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 1143, user, PFM::Text::PKNICK[1] => ally.given_name))
      end
    end
    Move.register(:s_ally_switch, AllySwitch)
  end
end
