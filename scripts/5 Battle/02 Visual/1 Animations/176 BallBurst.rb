module UI

  class BallBurst < SpriteSheet
    include RecenterSprite

    # Create a new BallBurst
    # @param viewport [Viewport]
    # @param pokemon_or_item [PFM::Pokemon, Studio::BallItem]
    def initialize(viewport, pokemon_or_item)
      super(viewport, 1, 20)
      resolve_image(pokemon_or_item)
      self.sy = 0
    end

    # Reset the Ballburst position
    # @param bank [Integer]
    # @param position [Integer]
    # @param scene [Battle::Scene]
    # @param start_battle [Boolean] coordinates offset for the start of the battle
    def reset_position(bank, position, scene, start_battle = false)
      set_position(*sprite_position(bank, position, scene))
      add_position(*offset_start_battle) if start_battle
      set_origin(width / 2, height / 2)
    end

    # Set the Ballburst position for retrieve animation
    # @param bank [Integer]
    # @param position [Integer]
    # @param scene [Battle::Scene]
    def retrieve_position(bank, position, scene)
      set_position(*retrieve_position(bank, position, scene))
      set_origin(width / 2, height / 2)
    end

    # Function that adjust the sy depending on the progression of the "open" animation
    # @param progression [Float]
    def open_progression=(progression)
      self.sy = (progression * 19).floor.clamp(0, 19)
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

      self.bitmap = RPG::Cache.ball("ball_burst/" + item.img)
      set_origin(width / 2, height / 2)
    end

    # Get the base position of the burst in 1v1
    # @param bank
    # @return [Array<Integer, Integer>]
    def base_position_v1(bank)
      return 250, 73 if bank == 1

      return 137, 90
    end

    # Get the base position of the burst in 2v2
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def base_position_v2(bank)
      return 211, 71 if bank == 1

      return 87, 73
    end

    # Return the offset used in 2v2 battle, based on the bank
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def offset_position_v2(bank)
      return 60, 9 if bank == 1

      return 71, 15
    end

    # Add of offset to the burst at the start of a battle
    # @return [Array<Integer, Integer>]
    def offset_start_battle
      return 32, 23
    end

    # Get the sprite position
    # @param bank [Integer]
    # @param position [Integer]
    # @param scene [Battle::Scene]
    # @return [Array<Integer, Integer>]
    def sprite_position(bank, position, scene)
      if scene.battle_info.vs_type == 1
        x, y = base_position_v1(bank)
      else
        x, y = base_position_v2(bank)
        dx, dy = offset_position_v2(bank)
        x += dx * position
        y += dy * position
      end
      return x, y
    end
  end
end