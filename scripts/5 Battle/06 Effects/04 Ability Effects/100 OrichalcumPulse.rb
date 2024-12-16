module Battle
  module Effects
    class Ability
      class OrichalcumPulse < Drought
        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 1 unless $env.sunny? || $env.hardsun?

          return 1.33
        end
      end

      register(:orichalcum_pulse, OrichalcumPulse)
    end
  end
end
