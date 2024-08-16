module Battle
  class Visual
    module Transition
      # Wild Sea transition of Black/White games
      class BWSeaWild < RBYWild
        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          time_updater = proc { |r| @screenshot_sprite.shader.set_float_uniform('time', r) }

          root = Yuki::Animation.send_command_to(self, :setup_shader, shader_name)
          root.play_before(Yuki::Animation.scalar(1.5, time_updater, :call, 0, 5))

          return root
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :bw_wild_sea
        end

        # Set up the shader
        # @param name [Symbol] name of the shader
        # @return [Shader]
        def setup_shader(name)
          @screenshot_sprite.shader = Shader.create(name)
          @screenshot_sprite.shader.set_float_uniform('textureWidth', @viewport.rect.width)
          @screenshot_sprite.shader.set_float_uniform('textureHeight', @viewport.rect.height)
        end
      end
    end

    WILD_TRANSITIONS[11] = Transition::BWSeaWild
  end
end
