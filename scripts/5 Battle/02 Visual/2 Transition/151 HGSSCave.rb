module Battle
  class Visual
    module Transition
      # Wild Cave transition of HeartGold/SoulSilver games
      class HGSSCaveWild < RBYWild
        private

        # Return the duration of pre_transtion cells
        # @return [Float]
        def pre_transition_cells_duration
          return 1.5
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'spritesheets/heartgold_soulsilver_cave_wild'
        end
      end
    end

    WILD_TRANSITIONS[6] = Transition::HGSSCaveWild
  end
end
