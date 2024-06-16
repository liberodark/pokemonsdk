module Battle
  class Visual
    module Transition
      class HGSSTrainer < DPPTrainer
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return '4g/hgss_trainer_1', '4g/hgss_trainer_2'
        end
      end
    end

    TRAINER_TRANSITIONS[4] = Transition::HGSSTrainer
    Visual.register_transition_resource(4, :sprite)
  end
end
