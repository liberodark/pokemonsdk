module Battle
  class Visual
    module Transition
      # Gym Leader transition of Diamant/Perle/Platine
      class DPPGymLeader < RBYTrainer
        # Start x coordinate of the bar
        BAR_START_X = 320
        # Y coordinate of the bar
        BAR_Y = 64
        # VS image x coordinate
        VS_X = 64
        # VS image y offset
        VS_OFFSET_Y = 30
        # Mugshot final x coordinate
        MUGSHOT_FINAL_X = BAR_START_X - 100
        # Mugshot pre final x coordinate (animation purposes)
        MUGSHOT_PRE_FINAL_X = MUGSHOT_FINAL_X - 20
        # Text offset Y
        TEXT_OFFSET_Y = 36

        # Update the transition
        def update
          super
          @default_battler_name = @scene.battle_info.battlers[1][0]
          @viewport.update
        end

        private

        # Get the enemy trainer name
        # @return [String]
        def trainer_name
          @scene.battle_info.names[1][0]
        end

        # Get the resource name according to the current state of the player and requested prefix
        # @param prefix [String] The prefix to use for the resource name
        # @return [String] The determined resource name
        def resource_name(prefix)
          resource_filename = @scene.battle_info.find_background_name_to_display(prefix) do |filename|
            next RPG::Cache.battleback_exist?(filename)
          end
          unless RPG::Cache.battleback_exist?(resource_filename)
            log_debug("Defaulting to file #{prefix}_#{@default_battler_name}")
            resource_filename = "#{prefix}_#{@default_battler_name}"
          end
          return resource_filename
        end

        # Function that creates all the sprites
        def create_all_sprites
          super
          create_vs_full_sprite
          create_vs_zoom_sprite
          create_mugshot_sprite
          Graphics.sort_z
        end

        # Function that creates the top sprite
        def create_top_sprite
          @bar = Sprite.new(@viewport)
          @bar.load(resource_name('vs_bar/bar_dpp'), :battleback)
          @bar.set_position(BAR_START_X, BAR_Y)

          @to_dispose << @screenshot_sprite << @bar
        end

        # Create VS sprite
        # @param bitmap [String] the bitmap filename
        # @param position [Array<Integer>] the x and y coordinates to set the sprite position
        # @return [LiteRGSS::Sprite] The created sprite
        def create_vs_sprite(bitmap, position, zoom)
          sprite = Sprite.new(@viewport)
          sprite.load(bitmap, :battleback)
          sprite.set_origin_div(2, 2)
          sprite.set_position(*position)
          sprite.zoom = zoom
          sprite.visible = false

          return sprite
        end

        # Create the full VS sprite
        def create_vs_full_sprite
          @vs_full = create_vs_sprite('vs_bar/vs_white', [VS_X, BAR_Y + VS_OFFSET_Y], 1)
          @to_dispose << @vs_full
        end

        # Create the VS zoom sprite
        def create_vs_zoom_sprite
          @vs_zoom = create_vs_sprite('vs_bar/vs_white', [VS_X, BAR_Y + VS_OFFSET_Y], 1)
          @to_dispose << @vs_zoom
        end

        # Function that creates the mugshot of the trainer
        def create_mugshot_sprite
          # @type [Sprite]
          @mugshot = Sprite.new(@viewport)
          @mugshot.load(resource_name('vs_bar/mugshot'), :battleback)
          @mugshot.set_position(BAR_START_X, BAR_Y)
          @mugshot.shader = Shader.create(:color_shader)
          @mugshot.shader.set_float_uniform('color', [0, 0, 0, 0.8])
          @mugshot_text = Text.new(0, @viewport, -1, BAR_Y + TEXT_OFFSET_Y, 0, 16, trainer_name, 2, nil, 10)

          @to_dispose << @mugshot << @mugshot_text
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_pre_transition_animation
          animation = Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 0)
          animation.play_before(Yuki::Animation.move(0.25, @bar, BAR_START_X, BAR_Y, 0, BAR_Y))
          animation.play_before(create_fade_in_animation)
          animation.play_before(Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 255))
          animation.play_before(Yuki::Animation.send_command_to(self, :dispose))

          return animation
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_fade_in_animation
          animation = Yuki::Animation.wait(4)
          animation.parallel_play(create_bar_loop_animation)
          animation.parallel_play(create_screenshot_shadow_animation)
          animation.parallel_play(create_vs_zoom_animation)
          animation.parallel_play(create_pre_transition_fade_out_animation)

          return animation
        end

        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_vs_zoom_animation
          animation = Yuki::Animation.wait(0.5)
          animation.play_before(Yuki::Animation.send_command_to(@vs_zoom, :visible=, true))
          animation.play_before(Yuki::Animation.scalar(0.15, @vs_zoom, :zoom=, 2, 1))
          animation.play_before(Yuki::Animation.scalar(0.15, @vs_zoom, :zoom=, 2, 1))
          animation.play_before(Yuki::Animation.scalar(0.15, @vs_zoom, :zoom=, 2, 1))
          animation.play_before(Yuki::Animation.send_command_to(@vs_zoom, :visible=, false))
          animation.play_before(Yuki::Animation.send_command_to(@vs_full, :visible=, true))
          animation.play_before(Yuki::Animation.move(0.4, @mugshot, BAR_START_X, BAR_Y, MUGSHOT_PRE_FINAL_X, BAR_Y))
          animation.play_before(Yuki::Animation.move(0.15, @mugshot, MUGSHOT_PRE_FINAL_X, BAR_Y, MUGSHOT_FINAL_X, BAR_Y))
          animation.play_before(Yuki::Animation.move_discreet(0.35, @mugshot_text, 0, @mugshot_text.y, MUGSHOT_PRE_FINAL_X, @mugshot_text.y))

          return animation
        end

        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_pre_transition_fade_out_animation
          transitioner = proc { |t| @viewport.shader.set_float_uniform('color', [1, 1, 1, t]) }

          animation = Yuki::Animation.wait(3.25)
          animation.play_before(Yuki::Animation.scalar(0.5, transitioner, :call, 0, 1))

          return animation
        end

        # Create the bar movement loop
        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_bar_loop_animation
          animation = Yuki::Animation.timed_loop_animation(0.25)
          movement = Yuki::Animation.move(0.25, @bar, 0, BAR_Y, -256, BAR_Y)

          return animation.parallel_play(movement)
        end

        # @return [Yuki::Animation::TimedAnimation] The created animation
        def create_screenshot_shadow_animation
          animation = Yuki::Animation.wait(1.5)
          animation.play_before(Yuki::Animation.send_command_to(self, :make_screenshot_shadow))

          return animation
        end

        def make_screenshot_shadow
          @screenshot_sprite.shader = Shader.create(:color_shader)
          @screenshot_sprite.shader.set_float_uniform('color', [0, 0, 0, 0.5])
          @mugshot.shader.set_float_uniform('color', [0, 0, 0, 0.0])
          @viewport.flash(Color.new(255, 255, 255), 20)
        end
      end
    end

    TRAINER_TRANSITIONS[3] = Transition::DPPGymLeader
    Visual.register_transition_resource(3, :sprite)
  end
end
