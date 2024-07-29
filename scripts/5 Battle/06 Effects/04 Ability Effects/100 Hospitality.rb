module Battle
  module Effects
    class Ability
      class Hospitality < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          return if handler.logic.allies_of(with).empty?

          random_ally = handler.logic.allies_of(with).sample
          hp = (random_ally.max_hp / 4).floor

          handler.scene.visual.show_ability(@target, true)
          handler.logic.damage_handler.heal(random_ally, hp)
          handler.scene.visual.hide_ability(@target)
        end
      end

      register(:hospitality, Hospitality)
    end
  end
end
