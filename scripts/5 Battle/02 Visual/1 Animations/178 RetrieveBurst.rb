module UI
  class RetrieveBurst < SpriteSheet

    COLUMNS = 8
    ROWS = 7
    MAX_INDEX = COLUMNS * ROWS - 1

    # Filename of the Spritesheet used
    BURST_FILENAME = 'ball-retreat'

    # Create a new RetrieveBurst
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport, COLUMNS, ROWS)
      self.bitmap = RPG::Cache.ball(BURST_FILENAME)
      set_origin(width / 2, height / 2)
      self.sy = 0
      self.sx = 0
    end

    # Function that adjust the bitmap depending of the "catch" animation
    # @param progression [Float]
    def retrieve_progression=(progression)
      index = (progression * MAX_INDEX).floor.clamp(0, MAX_INDEX)

      self.sx = index % COLUMNS
      self.sy = index / COLUMNS
    end
  end
end