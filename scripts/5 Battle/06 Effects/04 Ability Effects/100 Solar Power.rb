module Battle
  module Effects
    class Ability
      class SolarPower < Ability
        # Give the ats modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def ats_modifier
          return 1.5 if $env.sunny? || $env.hardsun?

          return super
        end

        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target) && ($env.sunny? || $env.hardsun?)
          return if @target.dead?

          scene.visual.show_ability(@target)
          logic.damage_handler.damage_change((@target.max_hp / 8).clamp(1, Float::INFINITY), @target)
        end
      end

      register(:solar_power, SolarPower)
    end
  end
end
