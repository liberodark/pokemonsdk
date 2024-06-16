module Battle
  class Visual
    module Transition
      # Wild Cave transition of HeartGold/SoulSilver games
      class HGSSWildCave < RBYWild
        private

        # Return the duration of pre_transtion cells
        # @return [Float]
        def pre_transition_cells_duration
          return 1.5
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return '4g/hgss_wild_cave'
        end
      end
    end

    WILD_TRANSITIONS[6] = Transition::HGSSWildCave
  end
end