module Battle
  module Effects
    class Ability
      class EmbodyAspect < Ability
        # Returns the stat boosted by the ability and the corresponding text.
        # @return [Array<Hash<Symbol, Integer>>]
        FORMS_DATA = {
          hearthflame_mask:  { stat: :atk, text: 1734 }, # Hearthflame (Fire)
          wellspring_mask:   { stat: :dfs, text: 1742 }, # Wellspring (Water)
          cornerstone_mask: { stat: :dfe, text: 1738 }  # Cornerstone (Rock)
        }
        FORMS_DATA.default = { stat: :spd, text: 1730 } # Teal (Grass)
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          return unless with.db_symbol == :ogerpon

          handler.scene.visual.show_ability(with)
          handler.scene.visual.wait_for_animation
          handler.scene.display_message_and_wait(parse_text_with_pokemon(66, FORMS_DATA[with.item_db_symbol][:text], with))
          handler.logic.stat_change_handler.stat_change_with_process(FORMS_DATA[with.item_db_symbol][:stat], 1, with)
        end
      end
      register(:embody_aspect, EmbodyAspect)
    end
  end
end
