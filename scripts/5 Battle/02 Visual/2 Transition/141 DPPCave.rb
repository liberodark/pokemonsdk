module Battle
  class Visual
    module Transition
      # Wild Cave transition of Diamant/Perle/Platine games
      class DPPCaveWild < RSCaveWild
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'shaders/diamant_perle_wild'
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          transitioner = proc { |t| @top_sprite.shader.set_float_uniform('t', t) }

          root = Yuki::Animation.send_command_to(@screenshot_sprite, :set_origin, @screenshot_sprite.width / 2, @screenshot_sprite.height / 2)
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :set_position, @viewport.rect.width / 2, @viewport.rect.height / 2))
          root.play_before(Yuki::Animation.scalar(1, transitioner, :call, 0, 1))
              .parallel_play(create_zoom_animation)

          return root
        end

        # Create a zoom animation on the player
        # @return [Yuki::Animation::TimedAnimation]
        def create_zoom_animation
          return Yuki::Animation.scalar(1, @screenshot_sprite, :zoom=, 1, 3)
        end
      end
    end

    WILD_TRANSITIONS[9] = Transition::DPPCaveWild
  end
end
