module Battle
  class Visual
    module Transition
      # Red transition of Heartgold/Soulsilver games
      class Red < RBYTrainer
        # Return the pre_transtion cells
        # @return [Array]
        def pre_transition_cells
          return 10, 3
        end

        # Return the duration of pre_transtion cells
        # @return [Float]
        def pre_transition_cells_duration
          return 1
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'pokeball_gold', 'spritesheets/crystal_wild'
        end

        # Function that creates the top sprite
        def create_top_sprite
          @top_sprite = ShaderedSprite.new(@viewport)
          @top_sprite.z = @screenshot_sprite.z * 2
          @top_sprite.load(pre_transition_sprite_name[0], :transition)
          @top_sprite.zoom = 0.75
          @top_sprite.y = (@viewport.rect.height - @top_sprite.height * @top_sprite.zoom_y) / 2
          @top_sprite.x = (@viewport.rect.width - @top_sprite.width * @top_sprite.zoom_x) / 2

          @cell_sprite = SpriteSheet.new(@viewport, *pre_transition_cells)
          @cell_sprite.z = @screenshot_sprite.z * 3
          @cell_sprite.load(pre_transition_sprite_name[1], :transition)
          @cell_sprite.zoom = @viewport.rect.width / @cell_sprite.width.to_f
          @cell_sprite.y = (@viewport.rect.height - @cell_sprite.height * @cell_sprite.zoom_y) / 2
          @cell_sprite.visible = false

          @to_dispose << @screenshot_sprite << @top_sprite << @cell_sprite
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          cells = (@cell_sprite.nb_x * @cell_sprite.nb_y).times.map { |i| [i % @cell_sprite.nb_x, i / @cell_sprite.nb_x] }

          root = create_flash_animation(1.5, 6)
          root.play_before(Yuki::Animation.send_command_to(@cell_sprite, :visible=, true))
          root.play_before(Yuki::Animation::SpriteSheetAnimation.new(pre_transition_cells_duration, @cell_sprite, cells))

          return root
        end
      end
    end

    TRAINER_TRANSITIONS[8] = Transition::Red
    Visual.register_transition_resource(8, :sprite)
  end
end
