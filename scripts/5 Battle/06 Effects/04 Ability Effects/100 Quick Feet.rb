module Battle
  module Effects
    class Ability
      class QuickFeet < Ability
        # Give the speed modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def spd_modifier
          return 1.5 if @target.status?

          return 1
        end
      end
      register(:quick_feet, QuickFeet)
    end
  end
end
