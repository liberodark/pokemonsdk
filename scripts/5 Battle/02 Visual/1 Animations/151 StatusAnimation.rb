module UI

  class StatusAnimation < SpriteSheet
    include RecenterSprite

    # Get the db_symbol of the status
    # @return [Symbol]
    attr_reader :status

    @registered_status = {}

    # Create a new StatusAnimation
    # @param viewport [Viewport]
    # @param status [Symbol] Symbol of the status
    # @param bank [Integer]
    def initialize(viewport, status, bank)
      @status = status
      @bank = bank
      @columns, @rows = status_dimension
      super(viewport, @columns, @rows)
      self.bitmap = RPG::Cache.animation(status_filename)
      self.sx = 0
      self.sy = 0
      set_origin(width / 2, height / 2)
    end

    class << self
      # Register a new status
      # @param db_symbol [Symbol] db_symbol of the status
      # @param klass [Class<StatusAnimation>] class of the status animation
      def register(db_symbol, klass)
        @registered_status[db_symbol] = klass
      end

      # Create a new Status animation
      # @param db_symbol [Symbol] db_symbol of the status
      # @return [StatusAnimation]
      def new(viewport, status, bank)
        klass = @registered_status[status] || StatusAnimation
        object = klass.allocate
        object.send(:initialize, viewport, status, bank)
        return object
      end
    end

    # Function that change the sprite according to the progression of the animation
    # @param progression [Float]
    def animation_progression=(progression)
      max_index = @columns * @rows - 1
      index = (progression * max_index).floor.clamp(0, max_index)
      self.sx = index % @columns
      self.sy = index / @columns
    end

    # setup the animation at the correct position
    # @param position [Integer]
    # @param battle_type [Integer]
    def animation_coordinates(position, battle_type)
      return set_position(*default_position(position, battle_type))
    end

    # Return the duration of the Status Animation
    # @param [Integer]
    def status_duration
      return 1
    end

    private

    # Return the position of the spritesheet
    # @param position [Integer]
    # @param battle_type [Integer]
    def default_position(position, battle_type)
      return status_position_1v1 if battle_type == 1

      base_position = status_position_2v2

      return base_position.map.with_index { |pos, i| pos + offset_position_v2[i] * position }
    end

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array<Integer, Integer>]
    def offset_position_v2
      return 60, 10
    end

    # Tell if the Animation is from the enemy side
    # @return [Boolean]
    def enemy?
      return @bank == 1
    end

    # Tell which type of battle it is
    # @return [Boolean]
    def battle_3d?
      return Battle::BATTLE_CAMERA_3D
    end

    # return the zoom value for the bitmap
    # @return [Integer]
    def zoom_value
      return 0.5 if enemy? || !(battle_3d? || enemy?)

      return 1
    end

    # Get the dimension of the Spritesheet
    # @return [Array<Integer, Integer>]
    def status_dimension
    end

    # Get the filename status
    # @return [String]
    def status_filename
    end
  end
end