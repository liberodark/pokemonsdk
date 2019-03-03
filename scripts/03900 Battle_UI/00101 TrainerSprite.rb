module Battle_UI
  # Sprite of a trainer shown in battle
  class TrainerSprite < ShaderedSprite
    # Create a new TrainerSprite
    # @param viewport [Viewport]
    # @param battler [String] name of the battler in graphics/battlers
    # @param bank [Integer] Bank where the Trainer is
    # @param rect [Array, Rect, nil] src_rect to apply (if it's animated)
    def initialize(viewport, battler, bank, rect = nil)
      super(viewport)
      @bank = bank
      set_bitmap(battler, :battler)
      set_position(basic_x_position, basic_y_position)
      self.z = basic_z_position
      self.src_rect.set(*rect) if rect
    end

    # Set the battler on its next frame
    # @note Frames are ordered on the vertical axis
    def show_next_frame
      new_y = src_rect.y + src_rect.height
      src_rect.y = new_y if new_y < bitmap.height
    end

    # Set the battler on its previous frame
    # @note Frames are ordered on the vertical axis
    def show_previous_frame
      new_y = src_rect.y - src_rect.height
      src_rect.y = new_y if new_y >= 0
    end

    private

    # Return the basic x position
    # @return [Integer]
    def basic_x_position
      return @bank == 0 ? 88 : 233
    end

    # Return the basic y position
    # @return [Integer]
    def basic_y_position
      y = @bank == 0 ? 174 : 94
      y += offset_y
      return y
    end

    # Return the offset_y of the battler
    # @return [Integer]
    def offset_y
      0
    end

    # Return the basic z position of the battler
    def basic_z_position
      return @bank == 0 ? 501 : 1
    end
  end
end