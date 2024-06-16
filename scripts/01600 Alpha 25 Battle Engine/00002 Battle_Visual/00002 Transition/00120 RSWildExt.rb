module Battle
  class Visual
    module Transition
      # Wild transition of Ruby/Saphir/Emerald/LeafGreen/FireRed games
      class RSWildExt < RBYWild
        # Function that creates the top sprite
        def create_top_sprite
          @screenshot_sprite_right = Sprite.new(@viewport)
          @screenshot_sprite_right.bitmap = @screenshot
          @screenshot_sprite_right.z = @screenshot_sprite.z + 1

          @black_screen = Sprite.new(@viewport)
          @black_screen.set_bitmap(black_sprite_name, :transition)
          @black_screen.z = @screenshot_sprite.z - 1

          @to_dispose << @screenshot_sprite << @black_screen
          @viewport.sort_z
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_animation
          root = create_flash_animation(1.5, 6)
          root.play_before(Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 0))
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :shader=, setup_shader(1)))
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite_right, :shader=, setup_shader(0)))
          root.play_before(start_parallel_animation)
          root.play_before(Yuki::Animation.wait(0.3))
          root.play_before(Yuki::Animation.send_command_to(self, :dispose))

          return root
        end

        # Start the animation of both screenshot_sprite
        def start_parallel_animation
          return sprite_left.parallel_play(sprite_right)
        end

        # Function that move the left screenshot_sprite
        # @return [Yuki::Animation::Dim2Animation]
        def sprite_left
          return Yuki::Animation.move(0.7, @screenshot_sprite, 0, 0, -@screenshot.width, 0)
        end

        # Function that move the right screenshot_sprite
        # @return [Yuki::Animation::Dim2Animation]
        def sprite_right
          return Yuki::Animation.move(0.7, @screenshot_sprite_right, 0, 0, @screenshot.width, 0)
        end

        # Set up the shader
        # @param line_offset [Integer] if line 0 or line 1 should be hidden
        # @return [Shader]
        def setup_shader(line_offset)
          shader = Shader.create(shader_name)
          shader.set_float_uniform('textureHeight', @screenshot.height)
          shader.set_int_uniform('lineOffset', line_offset)

          return shader
        end

        # The name of the shader
        # @return [Symbol]
        def shader_name
          return :rs_sprite_side
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def black_sprite_name
          return 'black_screen'
        end
      end
    end

    WILD_TRANSITIONS[3] = Transition::RSWildExt
  end
end

Graphics.on_start do
  Shader.register(:rs_sprite_side, 'graphics/shaders/rs_wild_ext_side.frag')
end
