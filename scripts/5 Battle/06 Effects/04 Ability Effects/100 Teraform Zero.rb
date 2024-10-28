module Battle
  module Effects
    class Ability
      class TeraformZero < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target

          weather_handler = handler.logic.weather_change_handler
          fterrain_handler = handler.logic.fterrain_change_handler
          return unless weather_handler.weather_appliable?(:none) || fterrain_handler.fterrain_appliable?(:none)

          handler.scene.visual.show_ability(with)
          handler.scene.visual.wait_for_animation

          weather_handler.weather_change(:none, nil) if weather_handler.weather_appliable?(:none)
          fterrain_handler.fterrain_change(:none) if fterrain_handler.fterrain_appliable?(:none)
        end
      end
      register(:teraform_zero, TeraformZero)
    end
  end
end
