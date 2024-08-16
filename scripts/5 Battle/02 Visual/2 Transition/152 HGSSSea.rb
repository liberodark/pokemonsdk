module Battle
  class Visual
    module Transition
      # Wild Sea transition of HeartGold/SoulSilver games
      class HGSSSeaWild < RBYWild
        # A hash mapping symbolic names to sprite paths
        # @type [Hash{Symbol => String}]
        SPRITE_NAMES = {
          first: 'assets/heartgold_soulsilver_sea_wild_01',
          second: 'assets/heartgold_soulsilver_sea_wild_02',
          third: 'black_screen'
        }

        # Function that returns an image name
        # @return [String]
        def pre_transition_sprite_name(sprite_name)
          return SPRITE_NAMES[sprite_name]
        end

        # Function that create a sprite
        # @param sprite_name [Symbol]
        # @param z_factor [Integer]
        # @param y_offset [Integer]
        # @return [Sprite]
        def create_sprite(sprite_name, z_factor, y_offset = 0)
          sprite = Sprite.new(@viewport)
          sprite.z = @screenshot_sprite.z * z_factor
          sprite.load(pre_transition_sprite_name(sprite_name), :transition)
          sprite.zoom = @viewport.rect.width / sprite.width.to_f
          sprite.y = @viewport.rect.height + y_offset
          sprite.visible = false

          return sprite
        end

        # Function that creates the top sprite
        def create_top_sprite
          @bubble_sprite = create_sprite(:first, 2)
          @wave_sprite = create_sprite(:second, 3)
          @black_sprite = create_sprite(:third, 4, @wave_sprite.height)
          @to_dispose << @bubble_sprite << @wave_sprite << @black_sprite << @screenshot_sprite
          @viewport.sort_z
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          root = Yuki::Animation.send_command_to(@screenshot_sprite, :shader=, setup_shader(shader_name))
          root.play_before(start_shader_animation)
              .parallel_play(start_bubble_animation)
              .parallel_play(start_wave_animation)
              .parallel_play(start_black_animation)

          return root
        end

        # Start the animation of the shader
        # @return [Yuki::Animation::ScalarAnimation]
        def start_shader_animation
          time_updater = proc { |r| @screenshot_sprite.shader.set_float_uniform('time', r) }
          time_animation = Yuki::Animation.scalar(1.5, time_updater, :call, 0, 5)

          return time_animation
        end

        # Start the animation of the bubble sprite
        # @return [Yuki::Animation::TimedAnimation]
        def start_bubble_animation
          root = Yuki::Animation.wait(0)
          root.play_before(Yuki::Animation.send_command_to(@bubble_sprite, :visible=, true))
          root.play_before(Yuki::Animation.scalar(1.5, @bubble_sprite, :y=, @bubble_sprite.y, -@viewport.rect.height))
              .parallel_play(oscillation_animation = Yuki::Animation.scalar(0.3, @bubble_sprite, :x=, @bubble_sprite.x, @bubble_sprite.x - 10, distortion: :SMOOTH_DISTORTION))
          oscillation_animation.play_before(Yuki::Animation.scalar(0.6, @bubble_sprite, :x=, @bubble_sprite.x - 10, @bubble_sprite.x + 10, distortion: :SIN))
          oscillation_animation.play_before(Yuki::Animation.scalar(0.6, @bubble_sprite, :x=, @bubble_sprite.x - 10, @bubble_sprite.x + 10, distortion: :SIN))

          return root
        end

        # Start the animation of the wave sprite
        # @return [Yuki::Animation::TimedAnimation]
        def start_wave_animation
          root = Yuki::Animation.wait(0.5)
          root.play_before(Yuki::Animation.send_command_to(@wave_sprite, :visible=, true))
          root.play_before(Yuki::Animation.move(1, @wave_sprite, @wave_sprite.x, @wave_sprite.y, @wave_sprite.x, -@viewport.rect.height))

          return root
        end

        # Start the animation of the black sprite
        # @return [Yuki::Animation::TimedAnimation]
        def start_black_animation
          root = Yuki::Animation.wait(0.5)
          root.play_before(Yuki::Animation.send_command_to(@black_sprite, :visible=, true))
          root.play_before(Yuki::Animation.move(1, @black_sprite, @black_sprite.x, @black_sprite.y, @black_sprite.x, -@viewport.rect.height + @wave_sprite.height))

          return root
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :sinusoidal
        end
      end
    end

    WILD_TRANSITIONS[7] = Transition::HGSSSeaWild
  end
end
