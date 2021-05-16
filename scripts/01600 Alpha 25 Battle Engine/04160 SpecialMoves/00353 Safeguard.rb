module Battle
  class Move
    # The user's party is protected from status conditions.
    # @see https://pokemondb.net/move/safeguard
    # @see https://bulbapedia.bulbagarden.net/wiki/Safeguard
    # @see https://www.pokepedia.fr/Rune_Protect
    class Safeguard < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if logic.bank_effects[user.bank].has?(db_symbol)
        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        logic.bank_effects[user.bank].add(Effects::Safeguard.new(logic, user.bank, 0, turn_count))
        scene.display_message_and_wait(parse_text(18, message_id + user.bank.clamp(0, 1)))
      end

      # Duration of the effect including the current turn
      # @return [Integer]
      def turn_count
        5
      end

      # Id of the message after the animation
      # @return [Integer]
      def message_id
        138
      end
    end
    Move.register(:s_safe_guard, Safeguard)
  end
end