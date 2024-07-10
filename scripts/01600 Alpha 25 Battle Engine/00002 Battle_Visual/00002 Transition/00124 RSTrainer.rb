module Battle
  class Visual
    module Transition
      # Trainer transition of Red/Blue/Yellow games
      class RSTrainer < RBYTrainer
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'shaders/ruby_saphir_trainer'
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          transitioner = proc { |t| @top_sprite.shader.set_float_uniform('t', t) }

          root = create_flash_animation(1.5, 6)
          root.play_before(Yuki::Animation.scalar(1, transitioner, :call, 0, 1))

          return root
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :black_to_white
        end
      end
    end

    TRAINER_TRANSITIONS[5] = Transition::RSTrainer
    Visual.register_transition_resource(5, :sprite)
  end
end
