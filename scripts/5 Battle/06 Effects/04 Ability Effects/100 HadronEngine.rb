module Battle
  module Effects
    class Ability
      class HadronEngine < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          return if handler.logic.field_terrain_effect.electric?

          turn_count = with.hold_item?(:terrain_extender) ? 8 : 5
          handler.scene.visual.show_ability(with, true)
          handler.logic.fterrain_change_handler.fterrain_change(:electric_terrain, turn_count, no_message: true)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(66, 1694, with))
          handler.scene.visual.hide_ability(with)
        end

        # Give the ats modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def ats_modifier
          return 1 unless @logic.field_terrain_effect.electric?

          return 1.33
        end
      end

      register(:hadron_engine, HadronEngine)
    end
  end
end
