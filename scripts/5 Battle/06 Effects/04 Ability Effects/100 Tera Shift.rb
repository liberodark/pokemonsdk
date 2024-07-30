module Battle
  module Effects
    class Ability
      class TeraShift < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return unless with == @target

          handler.scene.visual.show_ability(target)
          handler.scene.visual.wait_for_animation
          target.ability_index = 0 # can be nil, and we need to change ability after form_calibrate
          target.form_calibrate(:battle)
          handler.scene.visual.show_switch_form_animation(target)
        end
      end

      register(:tera_shift, TeraShift)
    end
  end
end
