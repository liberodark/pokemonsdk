module UI
  module MiningGame
    class KeyboardCursor < Sprite
      # Initialize the KeyboardCursor component
      # @param viewport [Viewport]
      # @param initial_coordinates [Array<Integer>] the initial coordinates defined by the INITIAL_CURSOR_COORDINATES constant
      def initialize(viewport, initial_coordinates)
        super(viewport)
        setup_attributes
        change_coordinates(initial_coordinates)
      end

      # Change the coordinates of the cursor to change its position
      # @param [Array<Integer>] array containing the x coordinate and the y coordinate
      def change_coordinates(coordinates)
        @coordinate_x = coordinates[0]
        @coordinate_y = coordinates[1]
        calibrate_position
      end

      private

      # Setup some attributes during the initialization of the Sprite
      def setup_attributes
        set_bitmap(image_filename, :interface)
        self.visible = false
      end

      # Calibrate the position of the cursor depending on its coordinates
      def calibrate_position
        x = base_x + sprite_induced_offset_x + (@coordinate_x * tile_texture_length)
        y = base_y + sprite_induced_offset_y + (@coordinate_y * tile_texture_width)
        set_position(x, y)
      end

      # Give the base x coordinate used to calibrate the cursor
      # @return [Integer]
      def base_x
        return 0
      end

      # Give the base y coordinate used to calibrate the cursor
      # @return [Integer]
      def base_y
        return 32
      end

      # Give the offset x induced by the sprite used to calibrate the cursor
      # @return [Integer]
      def sprite_induced_offset_x
        return -1
      end

      # Give the offset y induced by the sprite used to calibrate the cursor
      # @return [Integer]
      def sprite_induced_offset_y
        return -1
      end

      # Give the length of the texture of the mining tiles as defined in Tiled_Stack
      # @return [Integer]
      def tile_texture_length
        return Tiles_Stack::TEXTURE_LENGTH
      end

      # Give the width of the texture of the mining tiles as defined in Tiled_Stack
      # @return [Integer]
      def tile_texture_width
        return Tiles_Stack::TEXTURE_WIDTH
      end

      # Give the filename of the image used for this sprite
      # @return [String]
      def image_filename
        return 'mining_game/keyboard_cursor'
      end
    end
  end
end
