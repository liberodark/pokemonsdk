module Battle
  class Visual
    module Transition
      # Wild Sea transition of Diamant/Perle/Platine games
      class DPPSeaWild < RSCaveWild
        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'shaders/diamant_perle_sea_wild'
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          screenshot_sprite_updater = proc { |r| @screenshot_sprite.shader.set_float_uniform('time', r) }
          top_sprite_updater = proc { |t| @top_sprite.shader.set_float_uniform('t', t) }

          root = Yuki::Animation.send_command_to(@screenshot_sprite, :shader=, setup_shader(second_shader_name))
          root.play_before(Yuki::Animation.scalar(1.5, screenshot_sprite_updater, :call, 0, 5))
              .parallel_play(wait = Yuki::Animation.wait(0.5))
          wait.play_before(Yuki::Animation.scalar(1, top_sprite_updater, :call, 0, 2))

          return root
        end

        # Return the shader name
        # @return [Symbol]
        def second_shader_name
          return :sinusoidal
        end
      end
    end

    WILD_TRANSITIONS[12] = Transition::DPPSeaWild
  end
end
