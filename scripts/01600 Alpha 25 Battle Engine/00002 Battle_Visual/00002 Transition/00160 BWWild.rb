module Battle
  class Visual
    module Transition
      # Wild Sea transition of Black/White games
      class BWWild < RBYWild
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
          root.play_before(create_shader_animation)
          root.play_before(create_zoom_animation)

          return root
        end

        # Create a shader animation on the screen
        # @return [Yuki::Animation::TimedAnimation]
        def create_shader_animation
          radius_updater = proc { |radius| @screenshot_sprite.shader.set_float_uniform('radius', radius) }
          alpha_updater = proc { |alpha| @screenshot_sprite.shader.set_float_uniform('alpha', alpha) }
          tau_updater = proc { |tau| @screenshot_sprite.shader.set_float_uniform('tau', tau) }
          time_to_process = 0.6

          root = Yuki::Animation.wait(0)
          root.play_before(Yuki::Animation.scalar(time_to_process, radius_updater, :call, 0, 0.5))
              .parallel_play(Yuki::Animation.scalar(time_to_process, alpha_updater, :call, 1, 0.5))
              .parallel_play(Yuki::Animation.scalar(time_to_process, tau_updater, :call, 0.5, 1))

          return root
        end

        # Create a zoom animation on the player
        # @return [Yuki::Animation::TimedAnimation]
        def create_zoom_animation
          return Yuki::Animation.scalar(0.4, @screenshot_sprite, :zoom=, 1, 3)
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :yuki_weird
        end
      end
    end

    WILD_TRANSITIONS[8] = Transition::BWWild
  end
end
