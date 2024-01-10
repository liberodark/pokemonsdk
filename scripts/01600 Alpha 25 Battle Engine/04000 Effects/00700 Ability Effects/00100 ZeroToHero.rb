module Battle
  module Effects
    class Ability
      class ZeroToHero < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if who == with

          return should_activate?(who) if who == @target
          return switch_form(handler, with) if with == @target
        end

        # Check whether the ability should be activated when the pokémon returns to battle
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        def should_activate?(who)
          return if who.dead?
          return unless who.form == 0

          who.form_calibrate(:hero)
          who.ability_used = true
        end

        # Proceed with the change of form
        # @param handler [Battle::Logic::SwitchHandler]
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def switch_form(handler, with)
          return unless with.ability_used

          handler.scene.visual.show_ability(with)
          handler.scene.visual.show_switch_form_animation(with)
          with.ability_used = false
        end
      end
      register(:zero_to_hero, ZeroToHero)
    end
  end
end
