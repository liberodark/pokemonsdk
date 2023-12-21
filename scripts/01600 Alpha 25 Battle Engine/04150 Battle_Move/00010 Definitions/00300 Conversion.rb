module Battle
  class Move
    # Move that sets the type of the Pokemon as type of the first move
    class Conversion < BasicWithSuccessfulEffect
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        target = actual_targets.first
        target.type1 = user.moveset.first&.type || 0
        target.type2 = 0
        @scene.display_message_and_wait(parse_text_with_pokemon(19, 899, target, '[VAR TYPE(0001)]' => data_type(target.type1).name))
      end
    end

    # Move that sets the type of the Pokemon as type of the last move used by target
    class Conversion2 < BasicWithSuccessfulEffect
      # Return the exceptions to the Conversion 2 effect
      MOVE_EXCEPTIONS = %i[revelation_dance struggle]

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if targets.none? { |target| target.move_history.any? && !MOVE_EXCEPTIONS.include?(target.move_history.last.db_symbol) && target.move_history.last.move.type != 0 }
          show_usage_failure(user)
          return false
        end

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        last_move_user = actual_targets.max_by { |target| target.move_history.any? ? target.move_history.max_by(&:turn) : 0 }
        type = last_move_user.move_history&.last&.move&.type || 0
        user.type1 = random_resistances(type)
        user.type2 = 0
        @scene.display_message_and_wait(parse_text_with_pokemon(19, 899, user, '[VAR TYPE(0001)]' => data_type(user.type1).name))
      end

      # Check the resistances to one type and return one random
      # @param move_type [Integer] type of the move used by the target
      # @return Integer
      def random_resistances(move_type)
        resistances = each_data_type.select { |type| data_type(move_type).hit(type.db_symbol) < 1 }
        return resistances.sample.id
      end
    end
    Move.register(:s_conversion, Conversion)
    Move.register(:s_conversion2, Conversion2)
  end
end
