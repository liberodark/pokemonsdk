module Battle
  module Effects
    class Item
      class ThroatSpray < Item
        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless logic.current_action.is_a?(Actions::Attack)
          return unless logic.current_action.launcher == @target
          return if @target.dead?
          return unless logic.can_battle_continue?

          move = logic.current_action&.move
          return unless move.sound_attack?

          scene.visual.show_item(@target)
          scene.visual.wait_for_animation
          logic.stat_change_handler.stat_change_with_process(:ats, 1, @target, no_message: true)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 950, @target, PFM::Text::ITEM2[1] => @target.item_name))
          logic.item_change_handler.change_item(:none, true, @target)
        end
      end
      register(:throat_spray, ThroatSpray)
    end
  end
end
