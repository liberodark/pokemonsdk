module Battle
  module Effects
    class Item
      class FlameOrb < Item
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if @target.has_ability?(:magic_guard)
          return unless logic.status_change_handler.status_appliable?(:burn, @target)

          scene.display_message_and_wait(parse_text_with_pokemon(19, 258, @target, PFM::Text::ITEM2[1] => @target.item_name))
          apply_common_effects_with_fling(scene, @target)
        end

        # Apply the common effects of the item with Fling move effect
        # @param scene [Battle::Scene] battle scene
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def apply_common_effects_with_fling(scene, target, launcher = nil, skill = nil)
          scene.logic.status_change_handler.status_change(:burn, target, launcher, skill)
        end
      end

      register(:flame_orb, FlameOrb)
    end
  end
end
