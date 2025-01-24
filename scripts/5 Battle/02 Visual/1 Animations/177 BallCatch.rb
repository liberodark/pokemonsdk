module UI

  class BallCatch < SpriteSheet
    include RecenterSprite

    COLUMNS = 10
    ROWS = 9
    MAX_INDEX = COLUMNS * ROWS - 1

    # Create a new BallCatch
    # @param viewport [Viewport]
    # @param pokemon_or_item [PFM::Pokemon, Studio::BallItem]
    def initialize(viewport, pokemon_or_item)
      super(viewport, COLUMNS, ROWS)
      resolve_image(pokemon_or_item)
      self.sy = 0
      self.sx = 0
    end

    # Function that adjust the bitmap depending of the "catch" animation
    # @param progression [Float]
    def catch_progression=(progression)
      index = (progression * MAX_INDEX).floor.clamp(0, MAX_INDEX)

      self.sx = index % COLUMNS
      self.sy = index / COLUMNS
    end

    private

    # Resolve the sprite image
    # @param pokemon_or_item [PFM::Pokemon, Studio::BallItem]
    def resolve_image(pokemon_or_item)
      # @type [Studio::BallItem]
      item = pokemon_or_item.is_a?(PFM::Pokemon) ? data_item(pokemon_or_item.captured_with) : pokemon_or_item
      unless item.is_a?(Studio::BallItem)
        log_error("The parameter #{pokemon_or_item} did not endup into Studio::BallItem object...")
        return
      end

      self.bitmap = RPG::Cache.ball('ball_catch') # Different spritesheet will be made/used in the future
      set_origin(width / 2, height / 2)
    end
  end
end