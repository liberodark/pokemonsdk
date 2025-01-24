module UI
  # Sprite responsive of showing the sprite of the Ball we throw to Pokemon or to release Pokemon
  class ThrowingBallSprite3D < SpriteSheet
    include RecenterSprite

    # Array mapping the move progression to the right cell
    MOVE_PROGRESSION_CELL = [11, 12, 13, 12, 11, 14, 15, 16, 15, 14, 0]
    # Create a new ThrowingBallSprite
    # @param viewport [Viewport]
    # @param pokemon_or_item [PFM::Pokemon, Studio::BallItem]
    def initialize(viewport, pokemon_or_item)
      super(viewport, 1, 17)
      resolve_image(pokemon_or_item)
      self.sy = 3
      self.shader = Shader.create(:color_shader)
    end

    # Reset the ball position
    # @param bank [Integer]
    # @param position [Integer]
    # @param scene [Battle::Scene]
    # @param start_battle [Boolean] coordinates offset for the start of the battle
    def reset_position(bank, position, scene, start_battle = false)
      set_position(*sprite_position(bank, position, scene))
      add_position(*offset_start_battle) if start_battle
      set_origin(width / 2, height / 2)
    end

    # Set the ThrowingBall position for retrieve animation
    # @param bank [Integer]
    # @param position [Integer]
    # @param scene [Battle::Scene]
    def retrieve_position(bank, position, scene)
      set_position(*get_retrieve_position(bank, position, scene))
      set_origin(width / 2, height / 2)
    end

    # Function that adjust the sy depending on the progression of the "throw" animation
    # @param progression [Float]
    def throw_progression=(progression)
      self.sy = (progression * 7).floor % 7
    end

    # Function that adjust the sy depending on the progression of the "throw" animation (enemy only)
    # @param progression [Float]
    def throw_progression_enemy=(progression)
      self.sy = (progression * 7).floor.clamp(0, 7)
    end

    # Function that adjust the sy depending on the progression of the "open" animation
    # @param progression [Float]
    def open_progression=(progression)
      self.sy = progression.floor.clamp(0, 1) + 9
    end

    # Function that adjust the sy depending on the progression of the "close" animation
    # @param progression [Float]
    def close_progression=(progression)
      target = (progression * 9).floor
      self.sy = target == 9 ? 0 : 10
    end

    # Function that adjust the sy depending on the progression of the "move" animation
    # @param progression [Float]
    def move_progression=(progression)
      self.sy = MOVE_PROGRESSION_CELL[(progression * 10).floor]
    end

    # Function that adjust the sy depending on the progression of the "break" animation
    # @param progression [Float]
    def break_progression=(progression)
      self.sy = (progression * 7).floor.clamp(0, 6) + 20
    end

    # Function that adjust the sy depending on the progression of the "caught" animation
    # @param progression [Float]
    def caught_progression=(progression)
      target = (progression * 5).floor
      self.sy = target == 5 ? 17 : 27 + target
    end

    # Coordinate of the offset to match the apparition of the Pokemon
    # @param position [Integer]
    # @param scene [Battle::Scene]
    # @param start_battle [Boolean] coordinates offset for the start of the battle
    # @return [Array<Integer, Integer>]
    def actor_ball_offset(position, scene, start_battle = false)
      if scene.battle_info.vs_type == 1
        return start_battle ? [196, 48] : [161, 22]
      else
        return start_battle ? [189, 19] : [156, -14] if position == 0
        return start_battle ? [199, 28] : [167, -8]
      end
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

      self.bitmap = RPG::Cache.ball("battle_balls/" + item.img)
      set_origin(width / 2, height / 2)
    end

    # Get the base position of the ball in 1v1
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def base_position_v1(bank)
      return 242, 73 if bank == 1

      return 1, 155
    end

    # Get the base position of the ball in 2v2
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def base_position_v2(bank)
      return 200, 71 if bank == 1

      return 1, 155
    end

    def offset_position_v2(bank, scene)
      return 60, 9 if bank == 1

      # Puts both ball in the hand of the player
      return 0, 0 if scene.visual.battler_sprite(0, -2).nil?

      return 100, 0
    end

    # Add of offset to the ball at the start of a battle
    # @return [Array<Integer, Integer>]
    def offset_start_battle
      return 74, -45
    end

    # set the position of the ball the Pokemon is withdrawed in 1v1
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def retrieve_position_v1(bank)
      return 242, 138 if bank == 1

      return 107, 199
    end

    # set the position of the ball the Pokemon is withdrawed in 2v2
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def retrieve_position_v2(bank)
      return 201, 132 if bank == 1

      return 56, 219
    end

    # Offset between the two position in 2v2
    # @param bank [Integer]
    # @return [Array<Integer, Integer>]
    def retrieve_offset_v2(bank)
      return 60, 10 if bank == 1

      return 70, 5
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
        dx, dy = offset_position_v2(bank, scene)
        x += dx * position
        y += dy * position
      end
      return x, y
    end

    # Get the sprite position fo the retrieve of a Pokemon
    # @param bank [Integer]
    # @param position [Integer]
    # @param scene [Battle::Scene]
    # @return [Array<Integer, Integer>]
    def get_retrieve_position(bank, position, scene)
      if scene.battle_info.vs_type == 1
        x, y = retrieve_position_v1(bank)
      else
        x, y = retrieve_position_v2(bank)
        dx, dy = retrieve_offset_v2(bank)
        x += dx * position
        y += dy * position
      end
      return x, y
    end
  end
end
