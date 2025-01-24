module Battle
  # This script handles the camera movement

  class Visual3D
    # Default Margin_X : 64 (32px on each side), Margin_Y : 60 (30px on each side)
    # This constant handles the camera coordinates and all info related
    # It is composed by Array made like that :
    #[start_x, final_x, start_y, final_y, start_z, final_z, duration_of_the_movement, wait_after_the_movement]
    # -9 20 1 => is when the camera is centered on your creature (but it's not the real center of the screen, 0 0 1 is the real one) at default zoom (z = 1)
    CAMERA_TRANSLATION = [[0, -21, 0, 29, 1, 0.9, 2, 1], [-21, 15, 29, -19, 0.9, 1, 3, 1.25], [15, -44, -19, 6, 1, 1, 2.5, 1.5], [-44, 0, 6, 0, 1, 1, 1.4, 2]]

    # coordinates of the camera centered
    CAMERA_CENTER = [-9, 20, 1, 0.3]

    # Update the position of the camera
    def update_camera
      @camera_animation&.update
      @camera.apply_to(@sprites3D + @background.battleback_sprite3D)
    end

    # Define the camera animation across the Battle Scene
    def start_camera_animation
      stop_camera
      total_duration = CAMERA_TRANSLATION.sum { |translation| translation[-2] + translation[-1] }
      global_animation = Yuki::Animation::TimedLoopAnimation.new(total_duration+no_movement_duration) # total duration of the animation
      global_animation.play_before(Yuki::Animation.wait(no_movement_duration))
      CAMERA_TRANSLATION.each_with_index  do |translation, index|
        duration = translation[-2]
        wait_duration = translation[-1]
        if index == 0
          start_x, start_y, start_z = @camera.x, @camera.y, @camera.z
          final_x, final_y, final_z = translation[1], translation[3], translation[5]
        elsif index == (CAMERA_TRANSLATION.length - 1)
          start_x, start_y, start_z = translation[0], translation[2], translation[4]
          final_x, final_y, final_z = @camera.x, @camera.y, @camera.z
        else
          start_x, start_y, start_z = translation[0], translation[2], translation[4]
          final_x, final_y, final_z = translation[1], translation[3], translation[5]
        end
        animation = Yuki::Animation.scalar(duration, @camera_positionner, :x, start_x, final_x)
        animation.parallel_add(Yuki::Animation.scalar(duration, @camera_positionner, :y, start_y, final_y))
        animation.parallel_add(Yuki::Animation.scalar(duration, @camera_positionner, :z, start_z, final_z))
        animation.play_before(Yuki::Animation.wait(wait_duration))
        global_animation.play_before(animation)
      end
      @camera_animation = global_animation
      @camera_animation.resolver = self
      @camera_animation.start
    end

    # Define the translation to the center of the Screen
    def start_center_animation
      stop_camera
      duration = CAMERA_CENTER[3]
      animation = Yuki::Animation::ScalarAnimation.new(duration, @camera_positionner, :x, @camera.x, 0)
      animation.parallel_add(Yuki::Animation.scalar(duration, @camera_positionner, :y, @camera.y, 0))
      animation.parallel_add(Yuki::Animation.scalar(duration, @camera_positionner, :z, @camera.z, 1))
      @camera_animation = animation
      @camera_animation.start
    end

    # Time without moving at the beginning of start_camera_animation
    def no_movement_duration
      return 3
    end

    # delete all cameras
    def stop_camera
      @camera_animation = nil
    end

    # Center the camera on one of the sprite
    # @param bank [Integer]
    # @param position [Integer] default 0, will be use for next update
    def center_target(bank, position = 0)
      if @scene.battle_info.vs_type == 1
        coordinates = camera_zoom_1v1(bank)
      else
        coordinates = camera_zoom_2v2(bank, position)
      end
      animation = Yuki::Animation::ScalarAnimation.new(0.35, @camera_positionner, :x, @camera.x, coordinates[0])
      animation.parallel_add(Yuki::Animation.scalar(0.35, @camera_positionner, :y, @camera.y, coordinates[1]))
      animation.parallel_add(Yuki::Animation.scalar(0.35, @camera_positionner, :z, @camera.z, coordinates[2]))
      @camera_animation = animation
      @camera_animation.start
    end

    # Coordinates to zoom for the camera in 1v1
    # @param bank [Integer]
    # @return Array[<Float,Float,Float>]
    def camera_zoom_1v1(bank)
      return [56, -30, 1.4] if bank == 1

      return [-40, 13, 1.2]
    end

    # Coordinates to zoom for the camera in 2v2
    # @param bank [Integer]
    # @param position [Integer] default 0, will be use for next update
    # @return Array[<Float,Float,Float>]
    def camera_zoom_2v2(bank, position)
      # TODO (make coordinates more accurate, and dependent of the position)
      return [56, -30, 1.4] if bank == 1

      return [-40, 13, 1.2]
    end
  end
end