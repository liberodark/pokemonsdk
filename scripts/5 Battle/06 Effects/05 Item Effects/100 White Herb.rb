module Battle
  module Effects
    class Item
      class WhiteHerb < Item
        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if @target.battle_stage.none?(&:negative?)

          scene.visual.show_item(@target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1016, @target, PFM::Text::ITEM2[1] => @target.item_name))
          apply_common_effects_with_fling(scene, target)
          logic.item_change_handler.change_item(:none, true, @target)
        end

        # Apply the common effects of the item with Fling move effect
        # @param scene [Battle::Scene] battle scene
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def apply_common_effects_with_fling(scene, target, launcher = nil, skill = nil)
          target.battle_stage.map! { |stage| stage.negative? ? 0 : stage }
        end
      end

      register(:white_herb, WhiteHerb)
    end
  end
end
