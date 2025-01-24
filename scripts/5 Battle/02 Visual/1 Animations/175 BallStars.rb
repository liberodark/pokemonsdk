module UI
  class BallStars < SpriteSheet

    COLUMNS = 9
    ROWS = 7
    MAX_INDEX = COLUMNS * ROWS - 1

    # Filename of the Spritesheet used
    BALLSTARS_FILENAME = 'ball_stars'

    # Create a new BallStars
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport, COLUMNS, ROWS)
      self.bitmap = RPG::Cache.ball(BALLSTARS_FILENAME)
      self.sx = 0
      self.sy = 0
      set_origin(width / 2, height / 2)
    end

    # Function that adjust the bitmap depending of the "catch" animation
    # @param progression [Float]
    def catch_progression=(progression)
      index = (progression * MAX_INDEX).floor.clamp(0, MAX_INDEX)

      self.sx = index % COLUMNS
      self.sy = index / COLUMNS
    end
  end
end