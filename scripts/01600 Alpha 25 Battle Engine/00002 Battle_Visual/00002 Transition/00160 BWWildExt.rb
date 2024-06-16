module Battle
  class Visual
    module Transition
      # Wild Sea transition of Black/White games
      class BWWildExt < RBYWild
        # Function that creates the top sprite
        def create_top_sprite
          @screenshot_sprite.shader = setup_shader
          @to_dispose << @screenshot_sprite
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_animation
          root = create_flash_animation(1.5, 6)
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :set_origin, @screenshot_sprite.width / 2, @screenshot_sprite.height / 2))
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :set_position, @viewport.rect.width / 2, @viewport.rect.height / 2))
          root.play_before(create_shader_animation)
          root.play_before(create_zoom_animation)
          root.play_before(Yuki::Animation.send_command_to(self, :dispose))

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
          root = Yuki::Animation.wait(0)
          root.play_before(Yuki::Animation.scalar(0.4, @screenshot_sprite, :zoom=, 1, 3))

          return root
        end

        # Set up the shader
        # @return [Shader]
        def setup_shader
          shader = Shader.create(:weird)
          shader.set_float_uniform('radius', 0)
          shader.set_float_uniform('alpha', 1)
          shader.set_float_uniform('tau', 0.5)

          return shader
        end
      end
    end

    WILD_TRANSITIONS[8] = Transition::BWWildExt
  end
end

Graphics.on_start do
  Shader.register(:weird, 'graphics/shaders/yuki_transition_weird.txt')
end
