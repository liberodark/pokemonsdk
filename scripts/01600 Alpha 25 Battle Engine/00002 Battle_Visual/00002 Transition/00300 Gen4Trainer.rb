module Battle
  class Visual
    module Transition
      # Trainer Transition of gen6
      class Gen4Trainer < RBYTrainer
        private

        # Return the pre_transtion cells
        # @return [Array]
        def pre_transition_cells
          return 3, 4
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return '4g/trainer_4g_1', '4g/trainer_4g_2'
        end

        # Function that creates the top sprite
        def create_top_sprite
          @top_sprite = SpriteSheet.new(@viewport, *pre_transition_cells)
          @top_sprite.z = @screenshot_sprite.z * 2
          @top_sprite.set_bitmap(pre_transition_sprite_name[0], :transition)
          @top_sprite.zoom = @viewport.rect.width / @top_sprite.width.to_f
          @top_sprite.ox = @top_sprite.width / 2
          @top_sprite.oy = @top_sprite.height / 2
          @top_sprite.x = @viewport.rect.width / 2
          @top_sprite.y = @viewport.rect.height / 2
          @top_sprite.visible = false
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_animation
          flasher = proc do |x|
            sin = Math.sin(x)
            col = 0
            alpha = (sin.abs2.round(2) * 270).to_i
            @viewport.color.set(col, col, col, alpha)
          end
          ya = Yuki::Animation
          animation = ya::ScalarAnimation.new(0.7, flasher, :call, 0, 2 * Math::PI)
          animation.play_before(ya.send_command_to(@viewport.color, :set, 0, 0, 0, 0))
          animation.play_before(ya.send_command_to(@top_sprite, :visible=, true))
          animation.play_before(create_fadein_animation)
          animation.play_before(ya.send_command_to(@viewport.color, :set, 0, 0, 0, 255))
          animation.play_before(ya.send_command_to(@top_sprite, :dispose))
          animation.play_before(ya.send_command_to(@screenshot_sprite, :dispose))
          animation.play_before(ya.wait(0.25))
          return animation
        end

        # Function that creates the fade in animation
        def create_fadein_animation
          # We need to display all the cells in order so we will build an array from that
          cells = (@top_sprite.nb_x * @top_sprite.nb_y).times.map { |i| [i % @top_sprite.nb_x, i / @top_sprite.nb_x] }

          ya = Yuki::Animation
          animation = ya::ScalarAnimation.new(0.4, @top_sprite, :zoom=, 0.2, @viewport.rect.width / @top_sprite.width.to_f)
          animation << ya::ScalarAnimation.new(0.4, @top_sprite, :angle=, 90, -360)
          animation.play_before(ya::SpriteSheetAnimation.new(0.2, @top_sprite, cells))
          animation.play_before(ya.send_command_to(@top_sprite, :set_bitmap, pre_transition_sprite_name[1], :transition))
          animation.play_before(ya::SpriteSheetAnimation.new(0.2, @top_sprite, cells))
          animation.play_before(ya::send_command_to(@top_sprite, :dispose))
          # Prevent frame skipping between both SpriteSheet
          RPG::Cache.transition(pre_transition_sprite_name[1])
          return animation
        end
      end
    end

    TRAINER_TRANSITIONS[1] = Transition::Gen4Trainer
    Visual.register_transition_resource(1, :sprite)
  end
end
