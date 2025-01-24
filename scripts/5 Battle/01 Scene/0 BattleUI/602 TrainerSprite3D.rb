module BattleUI
  # Sprite of a Trainer in the battle when BATTLE_CAMERA_3D is set to true
  class TrainerSprite3D < TrainerSprite

    # Define the number of frames inside a back trainer
    BACK_FRAME_COUNT = 5

    def create_shader
      self.shader = Shader.create(:fake_3d)
    end

    # Set the z position of the sprite
    # @param z [Numeric]
    def z=(z)
      super(z+1)
      z = shader_z_position
      shader.set_float_uniform('z', z)
    end
    
    # Return the basic z position of the trainer
    def shader_z_position
      z = @bank == 0 ? 0.5 : 1
      return z
    end

    # Animation of player scrolling in and out at start of battle
    def send_ball_animation
      ya = Yuki::Animation
      animation = ya.wait(0.1)
      frames = DYNAMIC_BACKSPRITES ? @dynamic_frame_count : BACK_FRAME_COUNT
      frames.times do
        animation.play_before(ya.wait(0.1))
        animation.play_before(ya.send_command_to(self, :show_next_frame))
      end
      animation.play_before(ya.scalar(0.4, self, :opacity=, 255, 0))
      return animation
    end

    # Set the position of the battle_sprite for the ending phase of the battle and make it visible
    # @param position [Integer] position in the bank
    def set_end_battle_position(position)
      set_position(*base_position_end_battle(position))
    end

    # Get the position at the end of the battle for enemy
    # @param position [Integer] position in the bank
    # @return [Array<Integer, Integer>]
    def base_position_end_battle(position)
      return 238, 18 if @scene.battle_info.vs_type == 1 || @scene.battle_info.battlers[1].size < 2

      x, y = 200, 18
      x += offset_position_v2[0] * position
      y += offset_position_v2[1] * position

      return x,y
    end

    private

    # Get the base position of the Trainer in 1v1
    # @return [Array<Integer, Integer>]
    def base_position_v1
      return 82, 18 if enemy?

      return -80, 105
    end

    # Get the base position of the Trainer in 2v2
    # @return [Array<Integer, Integer>]
    def base_position_v2
      if enemy?
        return 34, 18 if @scene.battle_info.battlers[1].size >= 2

        return 82, 18
      end

      return -80, 105
    end

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array<Integer, Integer>]
    def offset_position_v2
      return 60, 0
    end

    # Creates the go_in animation
    # @return [Yuki::Animation::TimedAnimation]
    def go_in_animation
      return Yuki::Animation.wait(0)
    end

    # Creates the go_out animation
    # @return [Yuki::Animation::TimedAnimation]
    def go_out_animation
      return Yuki::Animation.wait(0)
    end
  end
end
