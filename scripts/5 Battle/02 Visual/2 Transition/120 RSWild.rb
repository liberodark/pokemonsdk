module Battle
  class Visual
    module Transition
      # Wild transition of Ruby/Saphir/Emerald/LeafGreen/FireRed games
      class RSWild < RBYWild
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'black_screen'
        end

        # Function that creates the top sprite
        def create_top_sprite
          @screenshot_sprite_right = Sprite.new(@viewport)
          @screenshot_sprite_right.bitmap = @screenshot
          @screenshot_sprite_right.z = @screenshot_sprite.z * 2

          @black_screen = Sprite.new(@viewport)
          @black_screen.load(pre_transition_sprite_name, :transition)
          @black_screen.z = @screenshot_sprite.z * 0.5

          @to_dispose << @screenshot_sprite << @screenshot_sprite_right << @black_screen
          @viewport.sort_z
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          root = Yuki::Animation.send_command_to(@screenshot_sprite, :shader=, setup_shader(shader_name, 1))
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite_right, :shader=, setup_shader(shader_name, 0)))
          root.play_before(Yuki::Animation.move(0.7, @screenshot_sprite, 0, 0, -@screenshot.width, 0))
              .parallel_play(Yuki::Animation.move(0.7, @screenshot_sprite_right, 0, 0, @screenshot.width, 0))

          return root
        end

        # Set up the shader
        # @param name [Symbol] name of the shader
        # @param line_offset [Integer] if line 0 or line 1 should be hidden
        # @return [Shader]
        def setup_shader(name, line_offset)
          shader = Shader.create(name)
          shader.set_float_uniform('textureHeight', @screenshot.height)
          shader.set_int_uniform('lineOffset', line_offset)

          return shader
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :rs_sprite_side
        end
      end
    end

    WILD_TRANSITIONS[3] = Transition::RSWild
  end
end
