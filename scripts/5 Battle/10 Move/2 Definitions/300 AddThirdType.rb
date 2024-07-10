module Battle
  class Move
    # Move that give a third type to an enemy
    class AddThirdType < Move
      TYPES = {
        trick_or_treat: :ghost,
        forest_s_curse: :grass
      }
            
      TYPES.default = :normal

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true if target.send(:"type_#{TYPES[db_symbol]}?")
        return true if target.has_ability?(:multitype) || target.has_ability?(:rks_system)

        return super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          target.type3 = new_type
          scene.display_message_and_wait(message(target))
        end
      end

      # Get the type given by the move
      # @return [Integer] the ID of the Type given by the move
      def new_type
        return data_type(TYPES[db_symbol] || 0).id
      end

      # Get the message text
      # @return [String]
      def message(target)
        return parse_text_with_pokemon(19, 902, target, '[VAR TYPE(0001)]' => data_type(new_type).name)
      end
    end
    Move.register(:s_add_type, AddThirdType)
  end
end
