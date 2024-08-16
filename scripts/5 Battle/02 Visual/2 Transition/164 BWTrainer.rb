module Battle
  class Visual
    module Transition
      # Trainer transition of Black/White games
      class BWTrainer < RBYTrainer
        # Function that creates the top sprite
        def create_top_sprite
          @screenshot_sprite.shader = setup_shader(shader_name)
          @to_dispose << @screenshot_sprite
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          root = Yuki::Animation.send_command_to(@screenshot_sprite, :set_origin, @screenshot_sprite.width / 2, @screenshot_sprite.height / 2)
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :set_position, @viewport.rect.width / 2, @viewport.rect.height / 2))
          root.play_before(create_zoom_animation)
          root.play_before(create_shader_animation)

          return root
        end

        # Create a shader animation on the screen
        # @return [Yuki::Animation::TimedAnimation]
        def create_shader_animation
          radius_updater = proc { |radius| @screenshot_sprite.shader.set_float_uniform('radius', radius) }
          alpha_updater = proc { |alpha| @screenshot_sprite.shader.set_float_uniform('alpha', alpha) }
          tau_updater = proc { |tau| @screenshot_sprite.shader.set_float_uniform('tau', tau) }
          time_to_process = 1.4

          root = Yuki::Animation.scalar(time_to_process, radius_updater, :call, 0, 0.5)
          root.parallel_play(Yuki::Animation.scalar(time_to_process, alpha_updater, :call, 1, 1))
          root.parallel_play(Yuki::Animation.scalar(time_to_process, tau_updater, :call, 0.5, 0.5))

          return root
        end

        # Create a zoom animation on the player
        # @return [Yuki::Animation::TimedAnimation]
        def create_zoom_animation
          return Yuki::Animation.scalar(0.1, @screenshot_sprite, :zoom=, 1, 1.1)
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :yuki_weird
        end
      end
    end

    TRAINER_TRANSITIONS[9] = Transition::BWTrainer
    Visual.register_transition_resource(9, :sprite)
  end
end
