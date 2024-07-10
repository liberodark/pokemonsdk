module Battle
  class Visual
    module Transition
      # Wild transition of Gold/Silver games
      class GoldWild < RBYWild
        private

        # Return the duration of pre_transtion cells
        # @return [Float]
        def pre_transition_cells_duration
          return 1
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'spritesheets/gold_wild'
        end
      end

      # Wild transition of Crystal game
      class CrystalWild < RBYWild
        private

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'spritesheets/crystal_wild'
        end
      end
    end

    WILD_TRANSITIONS[1] = Transition::GoldWild
    WILD_TRANSITIONS[2] = Transition::CrystalWild
  end
end
