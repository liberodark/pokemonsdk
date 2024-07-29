module Battle
  module Effects
    class Ability
      class SupersweetSyrup < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || with.ability_used
          return if handler.logic.foes_of(with).empty?

          handler.scene.visual.show_ability(with)
          with.ability_used = true

          foes = handler.logic.foes_of(with)
          foes.each { |foe| handler.logic.stat_change_handler.stat_change_with_process(:eva, -1, foe) }
        end
      end

      register(:supersweet_syrup, SupersweetSyrup)
    end
  end
end
