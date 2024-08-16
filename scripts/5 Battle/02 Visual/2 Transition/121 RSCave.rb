module Battle
  class Visual
    module Transition
      # Wild Cave transition of Ruby/Saphir/Emerald/LeafGreen/FireRed games
      class RSCaveWild < RBYWild
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'shaders/ruby_saphir_wild'
        end

        # Function that creates the top sprite
        def create_top_sprite
          @top_sprite = ShaderedSprite.new(@viewport)
          @top_sprite.z = @screenshot_sprite.z * 2
          @top_sprite.load(pre_transition_sprite_name, :transition)
          @top_sprite.zoom = @viewport.rect.width / @top_sprite.width.to_f
          @top_sprite.y = (@viewport.rect.height - @top_sprite.height * @top_sprite.zoom_y) / 2
          @top_sprite.shader = setup_shader(shader_name)
          @to_dispose << @screenshot_sprite << @top_sprite
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          transitioner = proc { |t| @top_sprite.shader.set_float_uniform('t', t) }

          return Yuki::Animation.scalar(1, transitioner, :call, 0, 1)
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :black_to_white
        end
      end
    end

    WILD_TRANSITIONS[10] = Transition::RSCaveWild
  end
end
