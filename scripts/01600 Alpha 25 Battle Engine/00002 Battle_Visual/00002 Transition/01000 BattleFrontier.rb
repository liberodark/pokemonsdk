module Battle
  class Visual
    module Transition
      # Trainer transition of Battle Frontier
      class BattleFrontierVertical < RSTrainer
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'shaders/battle_frontier_vertical'
        end
      end

      class BattleFrontierHorizontal < RSTrainer
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'shaders/battle_frontier_horizontal'
        end
      end
    end

    TRAINER_TRANSITIONS[6] = Transition::BattleFrontierVertical
    TRAINER_TRANSITIONS[7] = Transition::BattleFrontierHorizontal
    Visual.register_transition_resource(6, :sprite)
    Visual.register_transition_resource(7, :sprite)
  end
end
