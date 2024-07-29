module Battle
  module Effects
    class Item
      class MentalHerb < Item
        # List the db_symbol for every Mental effect
        # @return [Array<Symbol>]
        MENTAL_EFFECTS = %i[attract encore taunt torment heal_block disable]
        # Create a new item effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the item
        def initialize(logic, target, db_symbol)
          super
          @used_once = false
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return unless MENTAL_EFFECTS.any? { |effect| @target.effects.has?(effect) }

          apply_common_effects_with_fling(scene, @target)
          scene.visual.show_item(@target)
          logic.item_change_handler.change_item(:none, true, @target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1309, @target))
        end

        # Apply the common effects of the item with Fling move effect
        # @param scene [Battle::Scene] battle scene
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def apply_common_effects_with_fling(scene, target, launcher = nil, skill = nil)
          MENTAL_EFFECTS.each { |effect| eliminate_effect(effect, target) }
        end

        private

        # Function called to check and eliminate mental effects
        # @param effect_name [Symbol]
        # @param target [PFM::PokemonBattler]
        def eliminate_effect(effect_name, target)
          return if @used_once

          effect = target.effects.get(effect_name)
          return unless effect

          effect.kill
          @used_once = true
        end
      end
      register(:mental_herb, MentalHerb)
    end
  end
end
