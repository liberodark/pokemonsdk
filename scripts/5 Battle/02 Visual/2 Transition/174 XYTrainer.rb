module Battle
  class Visual
    module Transition
      # Trainer transition of X/Y games
      class XYTrainer < Base
        # Unitary deltaX of the background
        DX = -Math.cos(-3 * Math::PI / 180)
        # Unitary deltaY of the background
        DY = Math.sin(-3 * Math::PI / 180)

        private

        # Function that creates all the sprites
        def create_all_sprites
          super
          create_background
          create_degrade
          create_halos
          create_battlers
          create_shader
          @viewport.sort_z
        end

        def create_background
          @background = Sprite.new(@viewport).set_origin(@viewport.rect.width, @viewport.rect.height)
          @background.set_position(@viewport.rect.width / 2, @viewport.rect.height / 2)
          @background.load('battle_bg', :transition)
          @background.angle = -3
          @background.z = @screenshot_sprite.z - 1
          @to_dispose << @background
        end

        def create_degrade
          @degrade = Sprite.new(@viewport).set_origin(0, 90).set_position(0, 90).load('battle_deg', :transition)
          @degrade.zoom_y = 0.10
          @degrade.opacity = 255 * @degrade.zoom_y
          @degrade.z = @background.z
          @to_dispose << @degrade
        end

        def create_halos
          @halo1 = Sprite.new(@viewport).load('battle_halo1', :transition)
          @halo1.z = @background.z
          @to_dispose << @halo1
          @halo2 = Sprite.new(@viewport).set_origin(-640, 0).load('battle_halo2', :transition)
          @halo2.z = @background.z
          @to_dispose << @halo2
          @halo3 = Sprite.new(@viewport).set_origin(-640, 0).set_position(640, 0).load('battle_halo2', :transition)
          @halo3.z = @background.z
          @to_dispose << @halo3
        end

        def create_battlers
          @sprites = []

          positions = calculate_positions
          positions.each_with_index do |pos_x, index|
            sprite_small_filename, sprite_big_filename = *determine_battler_filename(@scene.battle_info.battlers[1][index])

            small_sprite = Sprite.new(@viewport)
            small_sprite.load(sprite_small_filename, :battler)
            small_sprite.set_position(-small_sprite.width / 4, @viewport.rect.height)
            small_sprite.set_origin(small_sprite.width / 2, small_sprite.height)
            small_sprite.z = @background.z

            big_sprite = Sprite.new(@viewport)
            big_sprite.load(sprite_big_filename, :battler)
            big_sprite.set_position(pos_x, @viewport.rect.height)
            big_sprite.set_origin(big_sprite.width / 2, big_sprite.height)
            big_sprite.z = @background.z
            big_sprite.opacity = 0

            @sprites << [small_sprite, big_sprite]
          end

          @actor_sprites = actor_sprites
        end

        # Determine the right filenames for the transition sprites
        # @param filename [String]
        # @return [Array<String>]
        def determine_battler_filename(filename)
          sprite_small_filename = "#{filename.gsub('_big', '')}_sma"
          sprite_big_filename = filename.include?('_big') ? filename : "#{filename}_big"
          return sprite_small_filename, sprite_big_filename
        end

        def create_shader
          @shader = Shader.create(:battle_backout)
          6.times do |i|
            @shader.set_texture_uniform("bk#{i}", RPG::Cache.transition("black_out0#{i}"))
          end
          @screenshot_sprite.shader = @shader
          @shader_time_update = proc { |t| @shader.set_float_uniform('time', t) }
        end

        def create_pre_transition_animation
          root = Yuki::Animation::ScalarAnimation.new(1.2, @shader_time_update, :call, 0, 1)
          root.play_before(Yuki::Animation.send_command_to(Graphics, :freeze))
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :dispose))
          return root
        end

        def create_background_animation
          background_setter = proc do |i|
            t = (1 - Math.cos(2 * Math::PI * i)) / 10 + i
            d = (t * 1200) % 120
            @background.set_position(d * DX + @viewport.rect.width / 2, d * DY + @viewport.rect.height / 2)
          end
          root = Yuki::Animation::TimedLoopAnimation.new(10)
          root.play_before(Yuki::Animation::ScalarAnimation.new(10, background_setter, :call, 0, 1))
          root.parallel_play(halo = Yuki::Animation::TimedLoopAnimation.new(0.5))
          halo.play_before(h1 = Yuki::Animation::ScalarAnimation.new(0.5, @halo2, :ox=, 0, 640))
          h1.parallel_play(Yuki::Animation::ScalarAnimation.new(0.5, @halo3, :ox=, 0, 640))
          return root
        end

        def create_paralax_animation
          root = Yuki::Animation.wait(0.1)
          root.play_before(Yuki::Animation::ScalarAnimation.new(0.4, @degrade, :zoom_y=, 0.10, 1.25))
          root.parallel_play(Yuki::Animation.opacity_change(0.2, @degrade, 0, 255))
          root.play_before(Yuki::Animation::ScalarAnimation.new(0.1, @degrade, :zoom_y=, 1.25, 1))
          return root
        end

        def create_sprite_move_animation
          root = Yuki::Animation.wait(0)
          parallel = nil

          positions = calculate_positions
          @sprites.each_with_index do |sprite, index|
            small_sprite, big_sprite = sprite
            end_x = positions[index]

            move_animation = Yuki::Animation.move(0.6, small_sprite, small_sprite.x, small_sprite.y, end_x, small_sprite.y)
            fade_animation = Yuki::Animation.opacity_change(0.4, small_sprite, 255, 0)
            fade_animation.parallel_play(Yuki::Animation.opacity_change(0.4, big_sprite, 0, 255))

            if index == 0
              root.play_before(parallel = move_animation)
              root.play_before(Yuki::Animation.wait(0.3))
              root.play_before(fade_animation)
            else
              parallel.parallel_play(move_animation)
              parallel.play_before(fade_animation)
            end
          end

          return root
        end

        def create_enemy_send_animation
          enemy_sprites.each { |sp| sp.visible = false }
          root = Yuki::Animation.wait(0)
          parallel = nil

          positions = calculate_positions
          @sprites.each_with_index do |sprite, index|
            _, big_sprite = sprite
            pos_x = positions[index] - 40

            move_animation = Yuki::Animation.move(0.6, big_sprite, big_sprite.x, big_sprite.y, pos_x, big_sprite.y)
            go_out_animation = Yuki::Animation.move(0.4, big_sprite, pos_x, big_sprite.y, @viewport.rect.width * 1.5, big_sprite.y)
            go_out_animation.parallel_play(Yuki::Animation.opacity_change(0.4, big_sprite, 255, 0))

            if index == 0
              root.play_before(parallel = move_animation)
              root.play_before(go_out_animation)
            else
              parallel.parallel_play(move_animation)
              parallel.play_before(go_out_animation)
            end
          end

          root.play_before(Yuki::Animation.send_command_to(Graphics, :freeze))
          root.play_before(Yuki::Animation.send_command_to(self, :hide_all_sprites))
          root.play_before(Yuki::Animation.send_command_to(Graphics, :transition))
          # TODO: Add Ball
          enemy_pokemon_sprites.each do |sp|
            root.play_before(Yuki::Animation.send_command_to(sp, :go_in))
          end
          return root
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

        # Function that create the animation of enemy sprite during the battle end
        # @return [Yuki::Animation::TimedAnimation]
        def show_enemy_sprite_battle_end
          root = Yuki::Animation.wait(0.3)

          positions = calculate_positions
          @sprites.each_with_index do |sprite, index|
            _, big_sprite = sprite
            pos_x = positions[index]

            root.play_before(go_in = Yuki::Animation.move(0.4, big_sprite, big_sprite.x, big_sprite.y, pos_x - 40, big_sprite.y))
            go_in.parallel_play(Yuki::Animation.opacity_change(0.4, big_sprite, 0, 255))
            root.play_before(Yuki::Animation.move(0.4, big_sprite, pos_x - 40, big_sprite.y, pos_x, big_sprite.y))
          end

          return root
        end

        # Function to calculate positions based on number of sprites
        # @param trainer_is_couple [Boolean]
        # @param vs_type [Array<Integer>]
        # @param width [Integer]
        # @return [Array<Integer>]
        def calculate_positions
          position_count = @scene.logic.battle_info.trainer_is_couple ? 1 : $game_temp.vs_type
          width = @viewport.rect.width

          case position_count
          when 1
            return [width / 2]
          when 2
            spacing = width / 3
            return [spacing, 2 * spacing]
          when 3
            spacing = width / 4
            return [spacing, 2 * spacing, 3 * spacing]
          else
            return []
          end
        end

        # Function that get out all battler sprites
        # @return [Yuki::Animation::TimedAnimation]
        def go_out_battlers
          # @type [Array<PokemonSprite>]
          battler_sprites = actor_pokemon_sprites + enemy_pokemon_sprites

          sprite_animations = Yuki::Animation.wait(0)
          battler_sprites.each do |sprite|
            sprite_animations.parallel_play(Yuki::Animation.send_command_to(sprite, :go_out))
          end

          return sprite_animations
        end

        def hide_all_sprites
          @to_dispose.each do |sprite|
            sprite.visible = false if sprite.is_a?(Sprite)
          end
        end
      end

      class Gen6Trainer < XYTrainer
      end
    end

    TRAINER_TRANSITIONS[0] = Transition::XYTrainer
    Visual.register_transition_resource(0, :artwork_full)
  end
end
