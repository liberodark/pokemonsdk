module Battle
  class Move
    # Move that give a third type to an enemy
    class ChangeType < Move
      TYPES = {
        soak: :water,
        magic_powder: :psychic
      }
      ABILITY_EXCEPTION = %i[multitype rks_system]
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.all? { |t| t.effects.has?(:change_type) || condition(t) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:change_type) || condition(target)

          target.effects.add(Battle::Effects::ChangeType.new(logic, target, new_type))
          scene.display_message_and_wait(message(target))
        end
      end

      # Method that tells if the Move's effect can proceed
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def condition(target)
        return type_check(target) && target.type2 == 0 && target.type3 == 0 || ABILITY_EXCEPTION.include?(target.ability_db_symbol) || target.effects.has?(:substitute)
      end

      # Method that tells if the target already has the type
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def type_check(target)
        return target.type_water?
      end

      # Get the type given by the move
      # @return [Integer] the ID of the Type given by the move
      def new_type
        return data_type(TYPES[db_symbol] || 0).id
      end

      # Get the message text
      # @return [String]
      def message(target)
        return parse_text_with_pokemon(19, 899, target, '[VAR TYPE(0001)]' => data_type(new_type).name)
      end
    end
    Move.register(:s_change_type, ChangeType)
  end
end
