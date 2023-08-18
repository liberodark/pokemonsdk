module Battle
  module Effects
    class Ability
      class Pickpocket < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target || !%i[none __undef__].include?(target.item_db_symbol)
          return unless skill&.direct? && launcher && launcher.hp > 0 && !launcher.has_ability?(:long_reach)
          return unless handler.logic.item_change_handler.can_lose_item?(launcher, target)
          return if launcher.has_ability?(:sheer_force) && launcher.ability_effect&.activated?

          handler.scene.visual.show_ability(target)

          text = parse_text_with_pokemon(*steal_text, launcher, PFM::Text::PKNICK[0] => launcher.given_name, PFM::Text::ITEM2[1] => launcher.item_name)
          handler.scene.display_message_and_wait(text)

          target.effects.get(:item_stolen).kill if target.effects.has?(:item_stolen)
          if $game_temp.trainer_battle
            @logic.item_change_handler.change_item(launcher.item_db_symbol, false, target, launcher, self)
            if launcher.from_party? && !launcher.effects.has?(:item_stolen)
              launcher.effects.add(Effects::ItemStolen.new(@logic, launcher))
            else
              @logic.item_change_handler.change_item(:none, true, launcher, launcher, self)
            end
          else # wild battle
            overwrite = target.from_party? && !launcher.from_party?
            @logic.item_change_handler.change_item(launcher.item_db_symbol, overwrite, target, launcher, self)
            @logic.item_change_handler.change_item(:none, false, launcher, launcher, self)
          end
        end

        # Function returning the file number and the line id of the text
        # @return [Array<Integer>]
        def steal_text
          return 19, 460
        end
      end
      register(:pickpocket, Pickpocket)

      class Magician < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if launcher != @target || launcher == target || !%i[none __undef__].include?(launcher.item_db_symbol)
          return unless launcher && launcher.hp > 0
          return unless handler.logic.item_change_handler.can_lose_item?(target, launcher)
          return if skill&.recoil? && (hp / skill.recoil_factor >= launcher.hp)
          return if skill&.direct? && (target.battle_item_db_symbol == :sticky_barb || (target.battle_item_db_symbol == :rocky_helmet && (launcher.max_hp / 6 >= launcher.hp)))

          handler.scene.visual.show_ability(launcher)
          text = parse_text_with_pokemon(*steal_text, launcher, '[VAR 1400(0002)]' => nil.to_s,
                                                                             '[VAR ITEM2(0002)]' => target.item_name,
                                                                             '[VAR PKNICK(0001)]' => target.given_name)
          handler.scene.display_message_and_wait(text)

          launcher.effects.get(:item_stolen).kill if launcher.effects.has?(:item_stolen)
          if $game_temp.trainer_battle
            @logic.item_change_handler.change_item(target.item_db_symbol, false, launcher, launcher, self)
            if target.from_party? && !target.effects.has?(:item_stolen)
              target.effects.add(Effects::ItemStolen.new(@logic, target))
            else
              @logic.item_change_handler.change_item(:none, true, target, launcher, self)
            end
          else # wild battle
            overwrite = launcher.from_party? && !target.from_party?
            @logic.item_change_handler.change_item(target.item_db_symbol, overwrite, launcher, launcher, self)
            @logic.item_change_handler.change_item(:none, false, target, launcher, self)
          end
        end

        # Function returning the file number and the line id of the text
        # @return [Array<Integer>]
        def steal_text
          return 19, 1063
        end
      end
      register(:magician, Magician)
    end
  end
end
