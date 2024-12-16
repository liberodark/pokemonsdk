module Battle
  module Effects
    class Ability
      class Plus < Ability
        # Give the ats modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def ats_modifier
          return 1 unless @logic.allies_of(@target).any? { |ally| ally.ability_effect.is_a?(Plus) }

          return 1.5
        end
      end

      register(:plus, Plus)
      register(:minus, Plus)
    end
  end
end
