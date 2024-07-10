module Battle
  class Move
    # Move that inflict Knock Off to the ennemy
    class KnockOff < BasicWithSuccessfulEffect
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return effect_working?(user, [target]) ? super * 1.5 : super
      end

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.any? { |target| @logic.item_change_handler.can_lose_item?(target, user) }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless @logic.item_change_handler.can_lose_item?(target, user)
          # Specific case : dying from Rocky Helmet or Rough Skin damage prevents from removing the target's item
          next if user.dead? && target.hold_item?(:rocky_helmet) || %i[rough_skin iron_barbs].include?(target.battle_ability_db_symbol)

          additionnal_variables = {
            PFM::Text::ITEM2[2] => target.item_name,
            PFM::Text::PKNICK[1] => target.given_name
          }
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 1056, user, additionnal_variables))
          if target.from_party? && !target.effects.has?(:item_stolen)
            @logic.item_change_handler.change_item(:none, false, target, user, self)
            target.effects.add(Effects::ItemStolen.new(@logic, target))
          else
            @logic.item_change_handler.change_item(:none, true, target, user, self)
          end
        end
      end
    end

    Move.register(:s_knock_off, KnockOff)
  end
end
