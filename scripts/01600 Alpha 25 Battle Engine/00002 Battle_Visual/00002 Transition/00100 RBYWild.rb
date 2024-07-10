module Battle
  class Visual
    module Transition
      # Wild transition of Red/Blue/Yellow games
      class RBYWild < Base
        # Constant giving the X displacement done by the sprites
        DISPLACEMENT_X = 360

        private

        # Return the pre_transtion cells
        # @return [Array]
        def pre_transition_cells
          return 10, 3
        end

        # Return the duration of pre_transtion cells
        # @return [Float]
        def pre_transition_cells_duration
          return 0.5
        end

        # Return the pre_transtion sprite name
        # @return [String]
        def pre_transition_sprite_name
          return 'spritesheets/rby_wild'
        end

        # Function that creates all the sprites
        def create_all_sprites
          super
          create_top_sprite
          create_enemy_sprites
          create_actors_sprites
        end

        # Function that creates the top sprite
        def create_top_sprite
          @top_sprite = SpriteSheet.new(@viewport, *pre_transition_cells)
          @top_sprite.z = @screenshot_sprite.z * 2
          @top_sprite.set_bitmap(pre_transition_sprite_name, :transition)
          @top_sprite.zoom = @viewport.rect.width / @top_sprite.width.to_f
          @top_sprite.y = (@viewport.rect.height - @top_sprite.height * @top_sprite.zoom_y) / 2
          @top_sprite.visible = false
          @to_dispose << @screenshot_sprite << @top_sprite
        end

        # Function that creates the enemy sprites
        def create_enemy_sprites
          color = [0, 0, 0, 1]
          @enemy_sprites = enemy_pokemon_sprites
          @enemy_sprites.each do |sprite|
            sprite.shader.set_float_uniform('color', color)
            sprite.x -= DISPLACEMENT_X
          end
        end

        # Function that creates the actor sprites
        def create_actors_sprites
          @actor_sprites = actor_sprites
          @actor_sprites.each do |sprite|
            sprite.x += DISPLACEMENT_X
          end
        end

        # Function that creates the Yuki::Animation related to the pre transition
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_animation
          animation = create_flash_animation(1.5, 6)
          animation.play_before(Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 0))
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

          animation = Yuki::Animation.send_command_to(@top_sprite, :visible=, true)
          animation.play_before(Yuki::Animation::SpriteSheetAnimation.new(pre_transition_cells_duration, @top_sprite, cells))

          return animation
        end

        # Function that create the fade out animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_out_animation
          animation = Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 0)
          animation.play_before(Yuki::Animation.send_command_to(Graphics, :transition, 15))
          return animation
        end

        # Function that create the sprite movement animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_sprite_move_animation
          ya = Yuki::Animation
          animations = @enemy_sprites.map do |sp|
            ya.move(0.8, sp, sp.x, sp.y, sp.x + DISPLACEMENT_X, sp.y)
          end
          # @type [Yuki::Animation::TimedAnimation]
          animation = animations.pop
          animations.each { |a| animation.parallel_add(a) }
          @actor_sprites.each do |sp|
            animation.parallel_add(ya.move(0.8, sp, sp.x, sp.y, sp.x - DISPLACEMENT_X, sp.y))
          end
          color = [0, 0, 0, 0]
          @enemy_sprites.select(&:shader).each { |sp| animation.play_before(ya.send_command_to(sp.shader, :set_float_uniform, 'color', color)) }
          cries = @enemy_sprites.select { |sp| sp.respond_to?(:cry) }
          cries.each { |sp| animation.play_before(ya.send_command_to(sp, :cry)) }
          return animation
        end

        # Function that create the animation of the player sending its Pokemon
        # @return [Yuki::Animation::TimedAnimation]
        def create_player_send_animation
          ya = Yuki::Animation
          animations = @actor_sprites.map do |sp|
            next ya.move(1, sp, sp.x, sp.y, -sp.width, sp.y).parallel_play(sp.send_ball_animation)
          end
          animation = animations.pop
          animations.each { |anim| animation.parallel_add(anim) }
          actor_pokemon_sprites.each do |sp|
            throwed_anim = ya.wait(0.3)
            throwed_anim.play_before(ya.send_command_to(sp, :go_in))
            animation.parallel_add(throwed_anim)
          end
          animation.play_before(ya.wait(0.2))
          return animation
        end

        # Set up the shader
        # @param name [Symbol] name of the shader
        # @return [Shader]
        def setup_shader(name)
          return Shader.create(name)
        end
      end
    end

    WILD_TRANSITIONS[0] = Transition::RBYWild
    WILD_TRANSITIONS.default = Transition::RBYWild
  end
end
