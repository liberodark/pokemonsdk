module Battle
  class Visual
    module Transition
      # Gym Leader transition of Heartgold/Soulsilver
      class HGSSGymLeader < DPPGymLeader
        # VS image y offset
        VS_OFFSET_Y = 35
        # Text offset Y
        TEXT_OFFSET_Y = 41
        # Function that creates the top sprite
        def create_top_sprite
          @bar = Sprite.new(@viewport)
          @bar.load(resource_name('vs_bar/bar_hgss'), :battleback)
          @bar.set_position(BAR_START_X, BAR_Y)

          @to_dispose << @screenshot_sprite << @bar
        end

        # Function that creates the mugshot of the trainer
        def create_mugshot_sprite
          super
          @mugshot.set_position(BAR_START_X, BAR_Y)
          @mugshot_text.set_position(-1, BAR_Y + TEXT_OFFSET_Y)
        end

        # Create the full VS sprite
        def create_vs_full_sprite
          @vs_full = create_vs_sprite('vs_bar/vs_red_crossed', [VS_X, BAR_Y + VS_OFFSET_Y], 0.5)
          @to_dispose << @vs_full
        end

        # Create the VS zoom sprite
        def create_vs_zoom_sprite
          @vs_zoom = create_vs_sprite('vs_bar/vs_red_crossed', [VS_X, BAR_Y + VS_OFFSET_Y], 0.5)
          @to_dispose << @vs_zoom
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_fade_in_animation
          animation = Yuki::Animation.wait(4)
          animation.parallel_play(create_bar_loop_animation)
          animation.parallel_play(create_screenshot_shadow_animation)
          animation.parallel_play(create_vs_zoom_animation)
          animation.parallel_play(create_pre_transition_fade_out_animation)
          animation.parallel_play(create_zoom_oscillation_animation)

          return animation
        end

        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_vs_zoom_animation
          animation = Yuki::Animation.wait(0.5)
          animation.play_before(Yuki::Animation.send_command_to(@vs_zoom, :visible=, true))
          animation.play_before(Yuki::Animation.scalar(0.15, @vs_zoom, :zoom=, 1, 0.5))
          animation.play_before(Yuki::Animation.scalar(0.15, @vs_zoom, :zoom=, 1, 0.5))
          animation.play_before(Yuki::Animation.scalar(0.15, @vs_zoom, :zoom=, 1, 0.5))
          animation.play_before(Yuki::Animation.send_command_to(@vs_zoom, :visible=, false))
          animation.play_before(Yuki::Animation.send_command_to(@vs_full, :visible=, true))
          animation.play_before(Yuki::Animation.move(0.4, @mugshot, BAR_START_X, BAR_Y, MUGSHOT_PRE_FINAL_X, BAR_Y))
          animation.play_before(Yuki::Animation.move(0.15, @mugshot, MUGSHOT_PRE_FINAL_X, BAR_Y, MUGSHOT_FINAL_X, BAR_Y))
          animation.play_before(Yuki::Animation.move_discreet(0.35, @mugshot_text, 0, @mugshot_text.y, MUGSHOT_PRE_FINAL_X, @mugshot_text.y))

          return animation
        end

        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_zoom_oscillation_animation
          animation = Yuki::Animation.timed_loop_animation(0.05)
          animation.parallel_play(Yuki::Animation.scalar(0.05, @vs_full, :x=, @vs_full.x - 1, @vs_full.x + 1, distortion: :SIN))
          animation.parallel_play(Yuki::Animation.scalar(0.05, @vs_full, :y=, @vs_full.y - 1, @vs_full.y + 1, distortion: :SIN))

          return animation
        end

        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_bar_loop_animation
          animation = Yuki::Animation.timed_loop_animation(0.15)
          movement = Yuki::Animation.move(0.15, @bar, 0, BAR_Y, -256, BAR_Y)

          return animation.parallel_play(movement)
        end
      end
    end

    TRAINER_TRANSITIONS[10] = Transition::HGSSGymLeader
    Visual.register_transition_resource(11, :sprite)
  end
end
