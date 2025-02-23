module Yuki
  module Animation
    module_function

    # Animation camera movement
    # @param target [Symbol] target of the camera movement
    # @param duration [Float] duration of the camera movement
    def camera_move_animation(target = :target, duration = 0.4)
      animation = Yuki::Animation.send_command_to(target, :center_camera)
      animation.play_before(Yuki::Animation.wait(duration))
      return animation
    end

    # Animation Recenter movement
    def camera_reset_position
      animation = Yuki::Animation.send_command_to(:visual, :start_center_animation)
      animation.play_before(Yuki::Animation.wait(0.3))
      return animation
    end
  end
end
