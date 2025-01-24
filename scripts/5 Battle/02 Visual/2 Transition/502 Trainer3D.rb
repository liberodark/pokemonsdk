module Battle
  class Visual3D
    module Transition3D
      class Trainer3D < RBYTrainer

        # Default duration for the animations
        ANIMATION_DURATION = 0.5

        # Dezoom for player send animation (last parameter is an angle for axe x)
        CAMERA_COORDINATES_PLAYER_SEND = [-35, 20, 0.90, 5]

        # Coordinates at the end of the transition for the camera
        CAMERA_END_COORDINATES = [0, 0, 1, 0]

        # Shader Color applying when the sprites appear
        SHADER_COLOR = [0, 0, 0, 1]

        # Create a new transition
        # @param scene [Battle::Scene]
        # @param screenshot [Texture]
        # @param camera [Fake3D::Camera]
        # @param camera_positionner [Visual3D::CameraPositionner]
        def initialize(scene, screenshot, camera, camera_positionner)
          super
          setup_camera_position
        end

        # Function that creates the top sprite
        def create_top_sprite
          @screenshot_sprite.shader = setup_shader(shader_name)
          @to_dispose << @screenshot_sprite
        end

        # Function that creates the enemy sprites
        def create_enemy_sprites
          @enemy_sprites = enemy_sprites
          @enemy_sprites.each do |sprite|
            sprite.shader.set_float_uniform('color', SHADER_COLOR)
          end
        end

        # Function that creates the actor sprites
        def create_actors_sprites
          @actor_sprites = actor_sprites
          @actor_sprites.each do |sprite|
            sprite.shader.set_float_uniform('color', SHADER_COLOR)
            sprite.opacity = 0
          end
          if Yuki::FollowMe.enabled
            actor_pokemon_sprites[0].follower_go_in_animation
          elsif $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION]
            actor_pokemon_sprites.each(&:follower_go_in_animation)
          end
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

          # Shader color animation for each sprite with a shader
          @enemy_sprites.select(&:shader).each do |sp|
            color_updater_enemy = proc do |progress|
              color = [0, 0, 0, progress]
              sp.shader.set_float_uniform('color', color)
            end

            # Add the color animation
            animation.parallel_add(ya.scalar(ANIMATION_DURATION, color_updater_enemy, :call, 1, 0))
          end

          @actor_sprites.select(&:shader).each do |sp|
            color_updater_actor = proc do |progress|
              color = [0, 0, 0, progress]
              sp.shader.set_float_uniform('color', color)
            end

          animation.parallel_add(ya.scalar(ANIMATION_DURATION, color_updater_actor, :call, 1, 0))
          end

          return animation
        end

        # Function that create the animation of the enemy sending its Pokemon
        # @return [Yuki::Animation::TimedAnimation]
        def create_enemy_send_animation
          ya = Yuki::Animation
          animations = @enemy_sprites.map do |sp|
            next ya.move(0.5, sp, sp.x, sp.y, sp.x + 40, sp.y - 10).parallel_play(ya.scalar(0.5, sp, :opacity=, 255, 0).play_before(ya.send_command_to(sp, :show_next_frame)).root)
          end
          animation = animations.pop
          animations.each { |anim| animation.parallel_add(anim) }
          enemy_pokemon_sprites.each do |sp|
            animation.play_before(ya.send_command_to(sp, :go_in))
          end
          return animation
        end

        # Function that creates the animation of the player sending its Pokemon
        # @return [Yuki::Animation::TimedAnimation
        def create_player_send_animation
          return Yuki::Animation.wait(0) if (Yuki::FollowMe.enabled && actor_pokemon_sprites.size == 1) || $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION]

          ya = Yuki::Animation
          animation = ya.wait(0)
          animation.parallel_add(dezoom_camera_animation)

          if @actor_sprites.length == 1
            animation.parallel_add(Yuki::Animation.opacity_change(ANIMATION_DURATION, @actor_sprites[0], 0, 255, distortion: cubic_distortion))
          elsif Yuki::FollowMe.enabled
            animation.parallel_add(Yuki::Animation.opacity_change(ANIMATION_DURATION, @actor_sprites[1], 0, 255, distortion: cubic_distortion))
          else
            @actor_sprites.each do |trainer|
              animation.parallel_add(Yuki::Animation.opacity_change(ANIMATION_DURATION, trainer, 0, 255, distortion: cubic_distortion))
            end
          end
          animation.play_before(ball_throw_player)
          animation.play_before(ya.wait(1.5))
          animation.play_before(reset_camera_animation)

          return animation
        end

        # Function that creates the animation of sending the ball(s) for each actor
        # @return [Yuki::Animation::TimedAnimation]
        def ball_throw_player
          return sending_ball_classic if @scene.battle_info.vs_type == 1
          return sending_ball_duo if @actor_sprites.length == 1

          return sending_ball_multi
        end

        # Function that creates the animation of sending the ball(s) in 1v1
        # @return [Yuki::Animation::TimedAnimation]
        def sending_ball_classic
          ya = Yuki::Animation
          pokemons = actor_pokemon_sprites
          trainers = @actor_sprites
          send_animation = ya.wait(0)

          trainer_animation = trainers[0].send_ball_animation
          pokemon_animation = ya.wait(wait_time_pokemon_animation)
          pokemon_animation.play_before(pokemons[0].go_in_animation(true))
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
          pokemons = actor_pokemon_sprites
          trainers = @actor_sprites
          send_animation = ya.wait(0)

          trainer_animation = trainers[0].send_ball_animation
          pokemon_animation = ya.wait(wait_time_pokemon_animation)
          pokemon_animation2 = ya.wait(wait_time_pokemon_animation)
          if Yuki::FollowMe.enabled
            pokemon_animation.play_before(pokemons[1].go_in_animation(true)) unless pokemons[1].nil?
          else
            pokemon_animation.play_before(pokemons[0].go_in_animation(true))
            pokemon_animation2.play_before(pokemons[1].go_in_animation(true)) unless pokemons[1].nil?
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
          pokemons = actor_pokemon_sprites
          trainers = @actor_sprites
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

          animation = ya.scalar(ANIMATION_DURATION, @camera_positionner, :x, @camera.x, CAMERA_COORDINATES_PLAYER_SEND[0])
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :y, @camera.y, CAMERA_COORDINATES_PLAYER_SEND[1]))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :z, @camera.z, CAMERA_COORDINATES_PLAYER_SEND[2]))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :rotate_x, 0, CAMERA_COORDINATES_PLAYER_SEND[3]))

          return animation
        end

        # Create the animation for resetting the camera to the center of the Battle Scene
        # @return [Yuki::Animation::TimedAnimation]
        def reset_camera_animation
          ya = Yuki::Animation
          x,y,z,axe_x = *CAMERA_COORDINATES_PLAYER_SEND
          end_x, end_y, end_z, end_axe_x = *CAMERA_END_COORDINATES

          animation = ya.scalar(ANIMATION_DURATION, @camera_positionner, :x, x, end_x)
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :y, y, end_y))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :z, z, end_z))
          animation.parallel_add(ya.scalar(ANIMATION_DURATION, @camera_positionner, :rotate_x, axe_x, end_axe_x))

          return animation
        end

        # Animation for the first trainer sending a ball
        # @return [Yuki::Animation::TimedAnimation]
        def trainer_send_ball_animation(index)
          ya = Yuki::Animation
          trainers = @actor_sprites
          animation = ya.wait(0)

          return animation.play_before(trainers[index].send_ball_animation) if index == 1
          return animation.play_before(trainers[index].send_ball_animation) if !($game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION] || Yuki::FollowMe.enabled)

          return animation
        end

        # Animation for a Pokémon going into battle
        # @param index [Integer] index of the Pokémon in the bank (0 or 1)
        # @return [Yuki::Animation::TimedAnimation]
        def pokemon_send_ball_animation(index)
          ya = Yuki::Animation
          pokemons = actor_pokemon_sprites
          animation = ya.wait(wait_time_pokemon_animation)

          if Yuki::FollowMe.enabled && index == 1
            animation.play_before(pokemons[1].go_in_animation(true))
          elsif !Yuki::FollowMe.enabled
            animation.play_before(pokemons[index].go_in_animation(true))
          end

          return animation
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          root = Yuki::Animation.send_command_to(@screenshot_sprite, :set_origin, @screenshot_sprite.width / 2, @screenshot_sprite.height / 2)
          root.play_before(Yuki::Animation.send_command_to(@screenshot_sprite, :set_position, @viewport.rect.width / 2, @viewport.rect.height / 2))
          root.play_before(create_zoom_animation)
          root.play_before(create_shader_animation)

          return root
        end

        # Function that create the fade out animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_out_animation
          ya = Yuki::Animation
          animation = ya.wait(0.1)
          return animation
        end

        # Create a shader animation on the screen
        # @return [Yuki::Animation::TimedAnimation]
        def create_shader_animation
          radius_updater = proc { |radius| @screenshot_sprite.shader.set_float_uniform('radius', radius) }
          alpha_updater = proc { |alpha| @screenshot_sprite.shader.set_float_uniform('alpha', alpha) }
          tau_updater = proc { |tau| @screenshot_sprite.shader.set_float_uniform('tau', tau) }
          time_to_process = 1.4

          root = Yuki::Animation.scalar(time_to_process, radius_updater, :call, 0, 0.5)
          root.parallel_play(Yuki::Animation.scalar(time_to_process, alpha_updater, :call, 1, 1))
          root.parallel_play(Yuki::Animation.scalar(time_to_process, tau_updater, :call, 0.5, 0.5))

          return root
        end

        # Function that create the animation of enemy sprite during the battle end
        # @return [Yuki::Animation::TimedAnimation]
        def show_enemy_sprite_battle_end
          temp_x, temp_y, temp_z = 48, 0, 1
          move = 40 * @scene.battle_info.vs_type
          ya = Yuki::Animation

          main_animation = ya.wait(0)
          sprite_animation = ya.wait(0)
          @enemy_sprites.each_with_index do |sprite, index|
            main_animation.play_before(ya.send_command_to(sprite, :set_end_battle_position, index))
            main_animation.play_before(ya.send_command_to(sprite, :opacity=, 255))
            x = sprite.base_position_end_battle(index)[0]
            sprite_animation.parallel_add(ya.scalar(ANIMATION_DURATION, sprite, :x=, x, x - move))
          end

          camera_move = Yuki::Animation.scalar(ANIMATION_DURATION, @camera_positionner, :x, @camera.x, temp_x)
          camera_move.parallel_add(Yuki::Animation.scalar(ANIMATION_DURATION, @camera_positionner, :y, @camera.y, temp_y))
          camera_move.parallel_add(Yuki::Animation.scalar(ANIMATION_DURATION, @camera_positionner, :z, @camera.z, temp_z))

          anim = ya.wait(1)
          anim.parallel_add(sprite_animation)
          anim.parallel_add(camera_move)

          main_animation.play_before(anim)

          return main_animation
        end

        # Create a zoom animation on the player
        # @return [Yuki::Animation::TimedAnimation]
        def create_zoom_animation
          return Yuki::Animation.scalar(0.1, @screenshot_sprite, :zoom=, 1, 1.1)
        end

        # Return the shader name
        # @return [Symbol]
        def shader_name
          return :yuki_weird
        end

        def setup_camera_position
          camera_x, camera_y = 0, 0
          enemies = enemy_pokemon_sprites
          enemies.each do |enemy|
            camera_x += enemy.x
            camera_y += enemy.y
          end

          @camera.set_position(100, -50, 1.8)
        end

        # Returns a cubic distortion for animations
        def cubic_distortion
          return proc{ |t| next t**3 }
        end

        # Waiting time before the pokemon out animation
        # @return [Float]
        def wait_time_pokemon_animation
          return 0.6
        end

      end
    end
    TRAINER_TRANSITIONS_3D[0] = Transition3D::Trainer3D
    TRAINER_TRANSITIONS_3D.default = Transition3D::Trainer3D
    Visual3D.register_transition_resource(0, :sprite)
  end
end