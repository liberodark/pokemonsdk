module Battle
  class Visual3D
    module Transition3D
      # In map Tansition same as RBYWild, in battle transition same as BW

      class WildTransition < Base
        # Default duration for the animations
        ANIMATION_DURATION = 0.5

        # Shader Color applying when the sprites appear
        SHADER_COLOR = [0, 0, 0, 1]

        # Coordinates at the end of the transition for the camera
        CAMERA_END_COORDINATES = [0, 0, 1, 0]

        # Dezoom for player send animation (last parameter is an angle for axe x)
        CAMERA_COORDINATES_PLAYER_SEND = [-35, 20, 0.90, 5]

        # Create a new transition
        # @param scene [Battle::Scene]
        # @param screenshot [Texture]
        # @param camera [Fake3D::Camera]
        # @param camera_positionner [Visual3D::CameraPositionner]
        def initialize(scene, screenshot, camera, camera_positionner)
          super
          setup_camera_position
        end

        private

        # Set the default position for the camera at the start
        def setup_camera_position
          @camera.set_position(100, -50, 1.8)
        end

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
          @top_sprite.load(pre_transition_sprite_name, :transition)
          @top_sprite.zoom = @viewport.rect.width / @top_sprite.width.to_f
          @top_sprite.y = (@viewport.rect.height - @top_sprite.height * @top_sprite.zoom_y) / 2
          @top_sprite.visible = false
          @to_dispose << @screenshot_sprite << @top_sprite
        end

        # Function that creates the enemy sprites
        def create_enemy_sprites
          @enemy_sprites = enemy_pokemon_sprites
          @enemy_sprites.each do |sprite|
            sprite.shader.set_float_uniform('color', SHADER_COLOR)
          end
        end

        # Function that creates the actor sprites
        def create_actors_sprites
          @actor_sprites = actor_sprites
          @actor_pokemon_sprites = actor_pokemon_sprites
          @actor_sprites.each do |sprite|
            sprite.shader.set_float_uniform('color', SHADER_COLOR)
            sprite.opacity = 0
          end
          if Yuki::FollowMe.enabled
            send_followers
          elsif $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION]
            @actor_pokemon_sprites.each(&:follower_go_in_animation)
          end
        end

        # Play the Follower go Animation on the right sprites
        def send_followers
          return false unless @actor_pokemon_sprites.any? { |actor_pokemon| actor_pokemon.pokemon.is_follower }

          @scene.battle_info.vs_type.times do |i|
            next unless @actor_pokemon_sprites[i].pokemon.is_follower
            next if @actor_sprites.length > 1 && i > 0

            @actor_pokemon_sprites[i].follower_go_in_animation
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
          animation = (Yuki::Animation.send_command_to(@viewport.color, :set, 0, 0, 0, 0))
          return animation
        end

        # Function that create the sprite movement animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_sprite_move_animation
          ya = Yuki::Animation
          animation = ya.wait(0.1)

          alpha_updater = proc do |alpha|
            @viewport.color.set(0, 0, 0, alpha)
          end
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, alpha_updater, :call, 1, 0))

          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :x, @camera.x, 0))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :y, @camera.y, 0))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :z, @camera.z, 1.0))

          cries = @enemy_sprites.select { |sp| sp.respond_to?(:cry) }
          cries.each do |sp|
            animation.play_before(ya.send_command_to(sp, :cry))
            animation.play_before(ya.send_command_to(sp, :shiny_animation))
          end

          apply_shader_animation(animation, @enemy_sprites)
          apply_shader_animation(animation, @actor_sprites)

          return animation
        end

        # Check if all the Pokémon on the field are sent
        def all_pokemon_on_field?
          return false if !(Yuki::FollowMe.enabled && Yuki::FollowMe.pokemon_count != 0)
          return @actor_pokemon_sprites[0].pokemon.is_follower if @scene.battle_info.vs_type == 1

          return (0..Yuki::FollowMe.pokemon_count).all? { |index| @actor_pokemon_sprites[index].pokemon.is_follower }
        end

        # Function that creates the animation of the player sending its Pokemon
        # @return [Yuki::Animation::TimedAnimation
        def create_player_send_animation
          return Yuki::Animation.wait(0) if all_pokemon_on_field? || $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION]

          ya = Yuki::Animation
          animation = dezoom_camera_animation

          @actor_sprites.each do |trainer|
            animation.parallel_add(Yuki::Animation.opacity_change(ANIMATION_DURATION, trainer, 0, 255, distortion: proc{ |t| next t**3 }))
          end

          # Play the animation of the player sending the ball
          animation.play_before(ball_throw_player)
          animation.play_before(ya.wait(1.5))
          animation.play_before(reset_camera_animation)

          return animation
        end

        # Function that creates the animation of sending the ball(s) for each actor
        # @return [Yuki::Animation::TimedAnimation]
        def ball_throw_player
          @trainer = @actor_sprites
          return sending_ball_classic if @scene.battle_info.vs_type == 1
          return sending_ball_duo if @actor_sprites.length == 1

          return sending_ball_multi
        end

        # Function that creates the animation of sending the ball(s) in 1v1
        # @return [Yuki::Animation::TimedAnimation]
        def sending_ball_classic
          ya = Yuki::Animation
          send_animation = ya.wait(0)

          trainer_animation = @trainer[0].send_ball_animation
          pokemon_animation = ya.wait(wait_time_pokemon_animation)
          pokemon_animation.play_before(@actor_pokemon_sprites[0].go_in_animation(true))
          wait_animation = ya.wait(1.5)

          send_animation.play_before(wait_animation)
          send_animation.parallel_add(trainer_animation)
          send_animation.parallel_add(pokemon_animation)

          return send_animation
        end

        # Function that creates the animation of sending the ball(s) in duo battle (no multi)
        # @return [Yuki::Animation::TimedAnimation]
        def sending_ball_duo
          ya = Yuki::Animation
          send_animation = ya.wait(0)

          trainer_animation = @trainer[0].send_ball_animation
          pokemon_animation = ya.wait(wait_time_pokemon_animation)
          pokemon_animation2 = ya.wait(wait_time_pokemon_animation)
          if @actor_pokemon_sprites[0].pokemon.is_follower
            pokemon_animation.play_before(@actor_pokemon_sprites[1].go_in_animation(true)) unless @actor_pokemon_sprites[1].nil?
          else
            pokemon_animation.play_before(@actor_pokemon_sprites[0].go_in_animation(true))
            pokemon_animation2.play_before(@actor_pokemon_sprites[1].go_in_animation(true)) unless @actor_pokemon_sprites[1].nil?
          end
          wait_animation = ya.wait(1.5)

          send_animation.play_before(wait_animation)
          send_animation.parallel_add(trainer_animation)
          send_animation.parallel_add(pokemon_animation)
          send_animation.parallel_add(pokemon_animation2)

          return send_animation
        end

        # Function that creates the animation of sending the ball(s) in multi battle
        # @return [Yuki::Animation::TimedAnimation]
        def sending_ball_multi
          ya = Yuki::Animation
          send_animation = ya.wait(0)

          send_animation.play_before(ya.wait(1.5))
          $game_temp.vs_type.times { |i| send_animation.parallel_add(trainer_send_ball_animation(i)) }
          $game_temp.vs_type.times { |i| send_animation.parallel_add(pokemon_send_ball_animation(i)) }

          return send_animation
        end

        # Create the dezoom animation for the player sending animation
        # @return [Yuki::Animation::TimedAnimation]
        def dezoom_camera_animation
          ya = Yuki::Animation
          x, y, z, axis_x = *CAMERA_COORDINATES_PLAYER_SEND

          animation = ya.scalar(ANIMATION_DURATION, @camera_positionner, :x, @camera.x, x)
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :y, @camera.y, y))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :z, @camera.z, z))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :rotate_x, 0, axis_x))

          return animation
        end

        # Create the animation for resetting the camera to the center of the Battle Scene
        # @return [Yuki::Animation::TimedAnimation]
        def reset_camera_animation
          ya = Yuki::Animation
          x, y, z, axis_x = *CAMERA_COORDINATES_PLAYER_SEND
          end_x, end_y, end_z, end_axe_x = *CAMERA_END_COORDINATES

          animation = ya.scalar(ANIMATION_DURATION, @camera_positionner, :x, x, end_x)
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :y, y, end_y))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :z, z, end_z))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :rotate_x, axis_x, end_axe_x))

          return animation
        end

        # Create a shader animation on the screen
        # @return [Yuki::Animation::TimedAnimation]
        def create_shader_animation
          radius_updater = proc { |radius| @screenshot_sprite.shader.set_float_uniform('radius', radius) }
          alpha_updater = proc { |alpha| @screenshot_sprite.shader.set_float_uniform('alpha', alpha) }
          tau_updater = proc { |tau| @screenshot_sprite.shader.set_float_uniform('tau', tau) }
          time_to_process = 0.6

          root = Yuki::Animation.wait(0)
          root.play_before(Yuki::Animation.scalar(time_to_process, radius_updater, :call, 0, 0.5))
              .parallel_play(Yuki::Animation.scalar(time_to_process, alpha_updater, :call, 1, 0.5))
              .parallel_play(Yuki::Animation.scalar(time_to_process, tau_updater, :call, 0.5, 1))

          return root
        end

        # Animation for the first trainer sending a ball
        # @return [Yuki::Animation::TimedAnimation]
        def trainer_send_ball_animation(index)
          ya = Yuki::Animation
          @trainer = @actor_sprites

          return @trainer[index].send_ball_animation unless $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION]

          return ya.wait(0)
        end

        # Animation for a Pokémon going into battle
        # @param index [Integer] index of the Pokémon in the bank (0 or 1)
        # @return [Yuki::Animation::TimedAnimation]
        def pokemon_send_ball_animation(index)
          ya = Yuki::Animation
          animation = ya.wait(create_shader_animation)

          unless @actor_pokemon_sprites[index].pokemon.is_follower
            animation.play_before(@actor_pokemon_sprites[index].go_in_animation(true))
          end

          return animation
        end

        # Apply shader color animation to sprites
        # @param animation [Yuki::Animation::TimedAnimation]
        # @param sprites [Array] list of sprites to animate
        def apply_shader_animation(animation, sprites)
          ya = Yuki::Animation
          sprites.select(&:shader).each do |sp|
            color_updater = proc do |progress|
              color = [0, 0, 0, progress]
              sp.shader.set_float_uniform('color', color)
            end
            animation.parallel_add(ya.scalar(ANIMATION_DURATION, color_updater, :call, 1, 0))
          end
        end

        # Set up the shader
        # @param name [Symbol] name of the shader
        # @return [Shader]
        def setup_shader(name)
          return Shader.create(name)
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :yuki_weird
        end

        # Waiting time before the pokemon out animation
        # @return [Float]
        def wait_time_pokemon_animation
          return 0.6
        end
      end
    end

    WILD_TRANSITIONS_3D[0] = Transition3D::WildTransition
    WILD_TRANSITIONS_3D.default = Transition3D::WildTransition
  end
end



