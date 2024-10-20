module BattleUI
  # Sprite of a Trainer in the battle when BATTLE_CAMERA_3D is set to true
  class TrainerSprite3D < TrainerSprite
    # Get the base position of the Trainer in 1v1
    # @return [Array(Integer, Integer)]
    def base_position_v1
      return 242, 108 if enemy?

      return 78, 188
    end

    # Get the base position of the Trainer in 2v2
    # @return [Array(Integer, Integer)]
    def base_position_v2
      if enemy?
        return 202, 103 if @scene.battle_info.battlers[1].size >= 2

        return 242, 108
      end

      return 58, 188
    end

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def offset_position_v2
      return 60, 0 unless enemy?

      return 60, 10
    end
  end
end
