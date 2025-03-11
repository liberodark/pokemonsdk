module Battle

  class Visual3D

    # Offsets for target coordinates based on type and conditions
    TARGET_COORDINATE_OFFSETS = {
      ball: {
        solo: [-50, -96],
        base_position_0: [-90, -77],
        base_position_1: [-28, -70]
      },
      stars: {
        solo: [-51, -11],
        base_position_0: [-91, 8],
        base_position_1: [-29, 15]
      },
      catch_burst: {
        solo: [-50, -93],
        base_position_0: [-90, -73],
        base_position_1: [-28, -66]
      },
      burst_break: {
        solo: [-39, 14],
        base_position_0: [-79, 54],
        base_position_1: [-17, 41]
      }
    }

    # Coordinates for the camera dependinng of the target
    CAMERA_CAPTURE_POSITION = {
      solo: [65, -10, 2],
      base_position_0: [65, -10, 2],
      base_position_1: [65, -10, 2]
    }

    # Show the catching animation
    # @param target_pokemon [PFM::PokemonBattler] pokemon being caught
    # @param ball [Studio::BallItem] ball used
    # @param nb_bounce [Integer] number of time the ball move
    # @param caught [Integer] if the pokemon got caught
    def show_catch_animation(target_pokemon, ball, nb_bounce, caught)
      @pokemon_to_catch = target_pokemon
      origin = battler_sprite(0, 0)
      target = battler_sprite(target_pokemon.bank, target_pokemon.position)
      @sprite = UI::ThrowingBallSprite3D.new(origin.viewport, ball)
      @burst_catch = UI::BallCatch.new(origin.viewport, ball)
      @burst2 = UI::BallBurst.new(origin.viewport, ball)
      animation = create_throw_ball_animation(@sprite, @burst_catch, target, origin)
      create_move_ball_animation(animation, @sprite, nb_bounce)
      caught ? create_caught_animation(animation, @sprite, target) : create_break_animation(animation, @burst2, @sprite, target)
      animation.start
      @animations << animation
      wait_for_animation
      start_center_animation unless caught
    end

    private

    # Create the throw ball animation
    # @param sprite [UI::ThrowingBallSprite]
    # @param burst_catch [UI::BallCatch]
    # @param target [Sprite]
    # @param origin [Sprite]
    # @return [Yuki::Animation::TimedAnimation]
    def create_throw_ball_animation(sprite, burst_catch, target, origin)
      ya = Yuki::Animation
      stop_camera
      sprite.set_position(*ball_origin_position)
      burst_catch.set_position(*animation_coordinates(target, :catch_burst))

      animation = throwing_animation(target, sprite)
      animation.play_before(ya.scalar(0.4, sprite, :throw_progression=, 0, 2))
      animation.play_before(ya.send_command_to(sprite, :sy=, 10))
      animation.play_before(create_enter_animation(target, burst_catch, sprite))
      animation.play_before(ya.scalar(0.5, sprite, :close_progression=, 0, 1))
      animation.play_before(ya.wait(0.1))
      fall_animation = create_fall_animation(target, sprite)
      sound_animation = sound_bounce_animation

      animation.play_before(fall_animation)
      fall_animation.parallel_play(sound_animation)

      return animation
    end


    # Create the throwing animation annd the zoom of the camera
    # @param target [Sprite]
    # @param sprite [UI::ThrowingBallSprite]
    # @return [Yuki::Animation::TimedAnimation]
    def throwing_animation(target, sprite)
      ya = Yuki::Animation
      camera_position = determine_camera_position

      animation = ya.scalar_offset(0.6, sprite, :y, :y=, 0, -64, distortion: :SQUARE010_DISTORTION)
      animation.parallel_play(ya.move(0.6, sprite, sprite.x, sprite.y, *animation_coordinates(target, :ball)))
      animation.parallel_play(ya.scalar(0.6, sprite, :throw_progression=, 0, 3))
      animation.parallel_play(ya.scalar(0.6, sprite, :zoom=, 3, 1))

      animation.parallel_play(ya.scalar(0.6, @camera_positionner, :x, @camera.x, camera_position[0]))
      animation.parallel_play(ya.scalar(0.6, @camera_positionner, :y, @camera.y, camera_position[1]))
      animation.parallel_play(ya.scalar(0.6, @camera_positionner, :z, @camera.z, camera_position[2]))
      animation.parallel_play(ya.se_play(*sending_ball_se))

      return animation
    end

    # Create the sound animation for the bouncing ball
    # @return [Yuki::Animation::TimedAnimation]
    def sound_bounce_animation
      ya = Yuki::Animation

      sound_animation = ya.wait(0.2)
      sound_animation.play_before(ya.se_play(*bouncing_ball_se))
      sound_animation.play_before(ya.wait(0.4))
      sound_animation.play_before(ya.se_play(*bouncing_ball_se))
      sound_animation.play_before(ya.wait(0.4))
      sound_animation.play_before(ya.se_play(*bouncing_ball_se))

      return sound_animation
    end

    # Create the fall animation
    # @param target [Sprite]
    # @param sprite [UI::ThrowingBallSprite]
    # @return [Yuki::Animation::TimedAnimation]
    def create_fall_animation(target, sprite)
      ya = Yuki::Animation

      fall_animation = ya.scalar(1, sprite, :y=, *animation_coordinates(target, :ball)[1] + 110, *animation_coordinates(target, :ball)[1], distortion: fall_distortion)
      fall_animation.parallel_add(ya.scalar(1, sprite, :throw_progression=, 0, 2))
      fall_animation.play_before(ya.send_command_to(sprite, :sy=, 0))
      fall_animation.play_before(ya.scalar(0.01, target, :y=, target.y, target.y))

      return fall_animation
    end

    # Create the fall animation
    # @param target [Sprite]
    # @param burst [UI::BallCatch]
    # @param sprite [UI::ThrowingBallSprite]
    # @return [Yuki::Animation::TimedAnimation]
    def create_enter_animation(target, burst_catch, sprite)
      color_updater_target = proc do |progress|
        color = [255, 255, 255, progress]
        target.shader.set_float_uniform('color', color)
      end
      ya = Yuki::Animation

      animation = ya.scalar(0.2, sprite, :open_progression=, 0, 1)

      enter_animation = ya.scalar(0.2, target, :zoom=, sprite_zoom, 0)
      enter_animation.parallel_add(ya.scalar(0.6, burst_catch, :catch_progression=, 1, 0))
      enter_animation.parallel_add(ya.scalar(0.2, target, :y=, target.y, target.y - 72))
      enter_animation.parallel_add(ya.scalar(0.2, color_updater_target, :call, 0, 1))
      enter_animation.parallel_add(ya.se_play(*opening_ball_se))
      enter_animation.play_before(ya.send_command_to(burst_catch, :dispose))

      return animation.play_before(enter_animation)
    end

    def fall_distortion
      return proc { |x| (Math.cos(2.5 * Math::PI * x) * Math.exp(-2 * x)).abs }
    end

    # Create the move animation
    # @param animation [Yuki::Animation::TimedAnimation]
    # @param sprite [UI::ThrowingBallSprite]
    # @param nb_bounce [Integer]
    def create_move_ball_animation(animation, sprite, nb_bounce)
      ya = Yuki::Animation
      animation.play_before(ya.wait(0.5))
      nb_bounce.clamp(0, 3).times do
        animation.play_before(ya.se_play(*moving_ball_se))
        animation.play_before(ya.scalar(0.5, sprite, :move_progression=, 0, 1))
        animation.play_before(ya.wait(0.5))
      end
    end

    # Create the move animation
    # @param animation [Yuki::Animation::TimedAnimation]
    # @param sprite [UI::ThrowingBallSprite]
    # @param target [Sprite]
    def create_caught_animation(animation, sprite, target)
      stars = UI::BallStars.new(sprite.viewport)
      stars.set_position(*animation_coordinates(target, :stars))
      ya = Yuki::Animation

      color_updater_ball = proc do |progress|
        color = [0, 0, 0, progress]
        sprite.shader.set_float_uniform('color', color)
      end

      animation.play_before(ya.se_play(*catching_ball_se))
      animation.play_before(ya.scalar(0.01, color_updater_ball, :call, 0, 0.5))
      animation.play_before(ya.scalar(1, stars, :catch_progression=, 0, 1))
    end

    # Create the break animation
    # @param animation [Yuki::Animation::TimedAnimation]
    # @param burst [UI::BallBurst]
    # @param sprite [UI::ThrowingBallSprite3D]
    # @param target [Sprite]
    def create_break_animation(animation, burst, sprite, target)
      ya = Yuki::Animation
      burst.opacity = 0
      burst.set_position(*animation_coordinates(target, :burst_break))

      animation.play_before(ya.se_play(*break_ball_se))
      animation.play_before(ya.send_command_to(burst, :opacity=, 255))
      animation.play_before(target_out_animation(target, burst, sprite))
      animation.play_before(ya.send_command_to(burst, :dispose))
    end

    # Create the exit animation for the Pokemon (when not catch)
    # @param burst [UI::BallBurst]
    # @param sprite [UI::ThrowingBallSprite3D]
    # @param target [Sprite]
    def target_out_animation(target, burst, sprite)
      ya = Yuki::Animation
      color_sprite_break = proc do |progress|
        color = [255, 255, 255, progress]
        target.shader.set_float_uniform('color', color)
      end

      animation = ya.send_command_to(sprite, :dispose)
      animation.parallel_add(ya.scalar(0.4, target, :zoom=, 0, sprite_zoom))
      animation.parallel_add(ya.scalar(0.4, color_sprite_break, :call, 1, 0))
      animation.parallel_add(ya.scalar(0.4, burst, :open_progression=, 0, 1))

      return animation
    end


    # Sprite zoom of the Pokemon battler
    # @return [Integer]
    def sprite_zoom
      return 1
    end

    # Coordinates whee the ball start before being throwned
    # @return [Array<Integer, Integer>]
    def ball_origin_position
      return -20, 180
    end

    # Return the coordinates based on the target, type, and offsets
    # @param target [Sprite] the target sprite
    # @param type [Symbol] the type of coordinates
    # @return [Array<Integer>] the calculated coordinates [x, y]
    def animation_coordinates(target, type)
      key = type_of_position
      x_offset, y_offset = TARGET_COORDINATE_OFFSETS.dig(type, key)

      return [target.x + HALF_WIDTH + x_offset, target.y + HALF_HEIGHT + y_offset]
    end

    # Return the "zoom position" of the camera
    # @return [Array<Integer>]
    def determine_camera_position
      key = type_of_position

      return CAMERA_CAPTURE_POSITION[key]
    end

    # Return the correct key depending of the battle and target
    # @return [:Symbol]
    def type_of_position
      return :solo if @scene.battle_info.vs_type == 1
      return :base_position_0 if @pokemon_to_catch.position == 0

      return :base_position_1
    end
  end
end