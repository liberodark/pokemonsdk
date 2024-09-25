module Battle
  module Effects
    class Item
      class BerserkGene < Item
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return unless with == @target

          handler.scene.visual.show_item(with)
          handler.logic.stat_change_handler.stat_change_with_process(:atk, 2, with)

          handler.logic.item_change_handler.change_item(:none, true, with)
          return if with.confused?
          # Specific Confusion setup since it lasts 256 turns unlike base confusion
          with.effects.add(Battle::Effects::Confusion.new(handler.logic, with, 256))
          handler.scene.visual.show_rmxp_animation(with, 475) # Confusion animation
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 345, with)) # Confusion text
        end
      end
      register(:berserk_gene, BerserkGene)
    end
  end
end
