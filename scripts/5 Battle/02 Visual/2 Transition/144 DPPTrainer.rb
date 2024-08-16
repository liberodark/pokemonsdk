module Battle
  class Visual
    module Transition
      # Trainer transition of Diamant/Perle/Platine games
      class DPPTrainer < RBYTrainer
        private

        # Return the pre_transtion cells
        # @return [Array]
        def pre_transition_cells
          return 3, 4
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'spritesheets/diamant_perle_trainer_01', 'spritesheets/diamant_perle_trainer_02'
        end

        # Function that creates the top sprite
        def create_top_sprite
          @top_sprite = SpriteSheet.new(@viewport, *pre_transition_cells)
          @top_sprite.z = @screenshot_sprite.z * 2
          @top_sprite.load(pre_transition_sprite_name[0], :transition)
          @top_sprite.zoom = @viewport.rect.width / @top_sprite.width.to_f
          @top_sprite.ox = @top_sprite.width / 2
          @top_sprite.oy = @top_sprite.height / 2
          @top_sprite.x = @viewport.rect.width / 2
          @top_sprite.y = @viewport.rect.height / 2
          @top_sprite.visible = false
          @to_dispose << @screenshot_sprite << @top_sprite
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_animation
          animation = create_flash_animation(0.7, 2)
          animation.play_before(Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 0))
          animation.play_before(Yuki::Animation.send_command_to(@top_sprite, :visible=, true))
          animation.play_before(create_fade_in_animation)
          animation.play_before(Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 255))
          animation.play_before(Yuki::Animation.send_command_to(self, :dispose))
          animation.play_before(Yuki::Animation.wait(0.25))
          return animation
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          # We need to display all the cells in order so we will build an array from that
          cells = (@top_sprite.nb_x * @top_sprite.nb_y).times.map { |i| [i % @top_sprite.nb_x, i / @top_sprite.nb_x] }

          animation = Yuki::Animation.scalar(0.4, @top_sprite, :zoom=, 0.2, @viewport.rect.width / @top_sprite.width.to_f)
          animation.parallel_play(Yuki::Animation.scalar(0.4, @top_sprite, :angle=, 90, -360))
          animation.play_before(Yuki::Animation::SpriteSheetAnimation.new(0.2, @top_sprite, cells))
          animation.play_before(Yuki::Animation.send_command_to(@top_sprite, :load, pre_transition_sprite_name[1], :transition))
          animation.play_before(Yuki::Animation::SpriteSheetAnimation.new(0.2, @top_sprite, cells))
          animation.play_before(Yuki::Animation.send_command_to(@top_sprite, :dispose))
          # Prevent frame skipping between both SpriteSheet
          RPG::Cache.transition(pre_transition_sprite_name[1])
          return animation
        end
      end

      class Gen4Trainer < DPPTrainer
      end
    end

    TRAINER_TRANSITIONS[1] = Transition::DPPTrainer
    Visual.register_transition_resource(1, :sprite)
  end
end
