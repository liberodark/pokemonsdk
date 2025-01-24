module UI

  class StatAnimation < SpriteSheet
    include RecenterSprite

    COLUMNS = 12
    ROWS = 10
    MAX_INDEX = COLUMNS * ROWS - 1

    # Create a new StatAnimation
    # @param viewport [Viewport]
    # @param amount [Integer]
    # @param z [Integer]
    # @param bank [Integer]
    def initialize(viewport, amount, z, bank)
      super(viewport, COLUMNS, ROWS)
      @amount = amount
      @bank = bank
      self.bitmap = RPG::Cache.animation(@amount > 0 ? "stat_up" : "stat_down")
      self.zoom = zoom_value
      self.sx = 0
      self.sy = 0
      self.z = z
      set_origin(width / 2, height)
      Graphics.sort_z
    end

    # Set the position of the stat animation
    # @param position [Integer]
    # @param battle_type [Integer]
    def animation_coordinates(position, battle_type)
      return set_position(*default_position(position, battle_type))
    end

    # Function that change the sprite according to the progression of the animation
    # @param progression [Float]
    def animation_progression=(progression)
      index = (progression * MAX_INDEX).floor.clamp(0, MAX_INDEX)

      self.sx = index % COLUMNS
      self.sy = index/COLUMNS
    end

    # Return the position of the spritesheet
    # @param position [Integer]
    # @param battle_type [Integer]
    def default_position(position, battle_type)
      return stat_position_1v1 if battle_type == 1

      base_position = stat_position_2v2

      return base_position.map.with_index { |pos, i| pos + offset_position_v2[i] * position }
    end

    # Get the base position of the status in 1v1
    # @return [Array<Integer, Integer>]
    def stat_position_1v1
      return enemy? ? [235, 141] : [105, 206] if battle_3d?

      return enemy? ? [241, 142] : [81, 185]
    end

    # Get the base position of the status in 2v2
    # @return [Array<Integer, Integer>]
    def stat_position_2v2
      return enemy? ? [201, 132] : [47, 229] if battle_3d?

      return enemy? ? [204, 132] : [54, 181]
    end

    # Return the offset used in 2v2 battle, based on the bank
    # @return [Array<Integer, Integer>]
    def offset_position_v2
      return 60, 10 if enemy? || !(battle_3d? || enemy?)

      return 96, 0
    end

    # return the zoom value for the bitmap
    # @return [Integer]
    def zoom_value
      return 0.5 if enemy? || !(battle_3d? || enemy?)

      return 1
    end

    # Tell which type of battle it is
    # @return [Boolean]
    def battle_3d?
      return Battle::BATTLE_CAMERA_3D
    end

    # Tell if the Animation is from the enemy side
    # @return [Boolean]
    def enemy?
      return @bank == 1
    end
  end
end