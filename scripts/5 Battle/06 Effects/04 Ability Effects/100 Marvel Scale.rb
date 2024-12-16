module Battle
  module Effects
    class Ability
      class MarvelScale < Ability
        # Give the dfe modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfe_modifier
          action = @logic.current_action
          return 1 unless @target.status?
          return 1 if action.is_a?(Actions::Attack) && !action.launcher.can_be_lowered_or_canceled?

          return 1.5
        end
      end

      register(:marvel_scale, MarvelScale)
    end
  end
end
