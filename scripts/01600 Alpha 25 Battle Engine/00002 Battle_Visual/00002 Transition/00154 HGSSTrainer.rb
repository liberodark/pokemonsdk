module Battle
  class Visual
    module Transition
      # Trainer transition of Heartgold/Soulsilver games
      class HGSSTrainer < DPPTrainer
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'spritesheets/heartgold_soulsilver_trainer_01', 'spritesheets/heartgold_soulsilver_trainer_02'
        end
      end
    end

    TRAINER_TRANSITIONS[4] = Transition::HGSSTrainer
    Visual.register_transition_resource(4, :sprite)
  end
end
