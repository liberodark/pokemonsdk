module Battle
  class Move
    # Class managing the Pluck move
    class Pluck < Basic
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return if user.dead?

        actual_targets.each do |target|
          next unless @logic.item_change_handler.can_lose_item?(target, user) && target.hold_berry?(target.battle_item_db_symbol)

          @scene.display_message_and_wait(parse_text_with_pokemon(19, 776, user, PFM::Text::ITEM2[1] => target.item_name))
          if target.item_effect.is_a?(Effects::Item::Berry)
            # @type [Effects::Item::Berry]
            user_effect = Effects::Item.new(logic, user, target.item_effect.db_symbol)
            user_effect.execute_berry_effect(force_heal: true, force_execution: true)
            if user.has_ability?(:cheek_pouch) && !user.effects.has?(:heal_block)
              @scene.visual.show_ability(user)
              @logic.damage_handler.heal(user, user.max_hp / 3)
            end


            user.effects.add(Effects::CudChewEffect.new(logic, user, user.ability_effect.turn_count, target.item_effect.db_symbol)) if user.has_ability?(:cud_chew)
          end
          @logic.item_change_handler.change_item(:none, true, target, user, self)
        end
      end
    end
    Move.register(:s_pluck, Pluck)
  end
end
