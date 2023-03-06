module Battle
  class Move
    # Implement the Burn Up move
    class BurnUp < Basic

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false unless user.type_fire?

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.effects.add(Effects::BurnUp.new(@logic, user, turn_count))
        scene.display_message_and_wait(parse_text_with_pokemon(59, 1856, user))
      end

      # Return the number of turns the effect works
      # @return Integer
      def turn_count
        return Float::INFINITY
      end
    end
    Move.register(:s_burn_up, BurnUp)
  end
end
