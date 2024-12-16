module Battle
  module Effects
    class Ability
      class SlowStart < Ability
        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 0.5 if @target.turn_count < 5

          return super
        end
        alias spd_modifier atk_modifier
      end

      register(:slow_start, SlowStart)
    end
  end
end
