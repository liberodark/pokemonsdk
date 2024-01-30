module Battle
  class Visual
    module Transition
      # Trainer transition of DPP Gym Leader
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
        # @return [String]
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

        # Function that creates the top sprite
        def create_top_sprite
          @bar = Sprite.new(@viewport)
          @bar.load(resource_name('vs_bar/bar_dpp'), :battleback)
          @bar.set_position(BAR_START_X, BAR_Y)
        end

        # Function that creates the vs sprites
        def create_vs_sprites
          @vs_full = Sprite.new(@viewport).load('vs_bar/vs_white', :battleback).set_origin_div(2, 2).set_position(VS_X, BAR_Y + VS_OFFSET_Y)
          @vs_border = Sprite.new(@viewport).load('vs_bar/vs_green', :battleback).set_origin_div(2, 2).set_position(VS_X, BAR_Y + VS_OFFSET_Y)
          @vs_woop_woop = Sprite.new(@viewport).load('vs_bar/vs_green', :battleback).set_origin_div(2, 2).set_position(VS_X, BAR_Y + VS_OFFSET_Y)
          @vs_full.visible = @vs_border.visible = @vs_woop_woop.visible = false
        end

        # Function that creates the mugshot of the trainer
        def create_mugshot_sprite
          @mugshot = Sprite.new(@viewport).load(resource_name('vs_bar/mugshot'), :battleback).set_position(BAR_START_X, BAR_Y)
          @mugshot.shader = Shader.create(:color_shader)
          @mugshot.shader.set_float_uniform('color', [0, 0, 0, 0.8])
          @mugshot_text = Text.new(0, @viewport, -1, BAR_Y + TEXT_OFFSET_Y, 0, 16, trainer_name, 2, nil, 10)
        end

        def dispose_all_pre_transition_sprites
          @screenshot_sprite.dispose
          @bar.dispose
          @vs_full.dispose
          @vs_border.dispose
          @vs_woop_woop.dispose
          @mugshot.dispose
          @mugshot_text.dispose
          @viewport.color.set(0, 0, 0, 255)
        end

        # Function that creates all the sprites
        def create_all_sprites
          super
          create_vs_sprites
          create_mugshot_sprite
          Graphics.sort_z
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_animation
          ya = Yuki::Animation
          anim = ya.move(0.25, @bar, BAR_START_X, BAR_Y, 0, BAR_Y)
          anim.play_before(create_parallel_loop(ya))
          anim.play_before(ya.send_command_to(self, :dispose_all_pre_transition_sprites))
          return anim
        end

        # @param [Module<Yuki::Animation>] ya
        def create_parallel_loop(ya)
          return ya.wait(4)
            .parallel_play(create_bar_loop_animation(ya))
            .parallel_play(create_screenshot_shadow_animation(ya))
            .parallel_play(create_vs_woop_woop_animation(ya))
            .parallel_play(create_pre_transition_fade_out_animation(ya))
        end

        # @param [Module<Yuki::Animation>] ya
        def create_vs_woop_woop_animation(ya)
          vs_woop_woop_anim = ya.wait(0.5)
          vs_woop_woop_anim.play_before(ya.send_command_to(self, :show_vs))
          vs_woop_woop_anim.play_before(ya.scalar(0.15, @vs_woop_woop, :zoom=, 2, 1))
          vs_woop_woop_anim.play_before(ya.scalar(0.15, @vs_woop_woop, :zoom=, 2, 1))
          vs_woop_woop_anim.play_before(ya.scalar(0.15, @vs_woop_woop, :zoom=, 2, 1))
          vs_woop_woop_anim.play_before(ya.send_command_to(@vs_full, :visible=, true))
          vs_woop_woop_anim.play_before(ya.move(0.4, @mugshot, BAR_START_X, BAR_Y, MUGSHOT_PRE_FINAL_X, BAR_Y))
          vs_woop_woop_anim.play_before(ya.move(0.15, @mugshot, MUGSHOT_PRE_FINAL_X, BAR_Y, MUGSHOT_FINAL_X, BAR_Y))
          vs_woop_woop_anim.play_before(ya.move_discreet(0.35, @mugshot_text, 0, @mugshot_text.y, MUGSHOT_PRE_FINAL_X, @mugshot_text.y))
          return vs_woop_woop_anim
        end

        # @param [Module<Yuki::Animation>] ya
        def create_pre_transition_fade_out_animation(ya)
          transitioner = proc { |t| @viewport.shader.set_float_uniform('color', [1, 1, 1, t]) }
          fade_out = ya.wait(3.25)
          fade_out.play_before(ya.scalar(0.5, transitioner, :call, 0, 1))
          return fade_out
        end

        # @param [Module<Yuki::Animation>] ya
        def create_screenshot_shadow_animation(ya)
          shadow_anim = ya.wait(1.5)
          shadow_anim.play_before(ya.send_command_to(self, :make_screenshot_shadow))
          return shadow_anim
        end

        # @param [Module<Yuki::Animation>] ya
        def create_bar_loop_animation(ya)
          anim = ya.timed_loop_animation(0.25)
          movement = ya.move(0.25, @bar, 0, BAR_Y, -256, BAR_Y)
          return anim.parallel_play(movement)
        end

        def make_screenshot_shadow
          @screenshot_sprite.shader = Shader.create(:color_shader)
          @screenshot_sprite.shader.set_float_uniform('color', [0, 0, 0, 0.5])
          @mugshot.shader.set_float_uniform('color', [0, 0, 0, 0.0])
          @viewport.flash(Color.new(255, 255, 255), 20)
        end

        def show_vs
          @vs_border.visible = @vs_woop_woop.visible = true
        end
      end
    end

    TRAINER_TRANSITIONS[3] = Transition::DPPGymLeader
    Visual.register_transition_resource(3, :sprite)
  end
end
