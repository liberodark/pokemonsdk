module Yuki
  class Tilemap
    # Class containing the map Data and its resources
    class MapData
      # List of method that help to load the position
      POSITION_LOADERS = {
        north: :load_position_north,
        south: :load_position_south,
        east: :load_position_east,
        west: :load_position_west,
        self: :load_position_self
      }
      # Get access to the original map data
      # @return [RPG::Map]
      attr_reader :map
      # Get the map X coordinate range
      # @return [Range]
      attr_reader :x_range
      # Get the map Y coordinate range
      # @return [Range]
      attr_reader :y_range

      # Create a new MapData
      # @param map [RPG::Map]
      def initialize(map)
        @data = map.data
        @map = map
        @rect = Rect.new(0, 0, 32, 32)
      end

      # Sets the position of the map in the 2D Space
      # @param map [RPG::Map] current map
      # @param side [Symbol] which side the map is (:north, :south, :east, :west)
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      def load_position(map, side, offset)
        maker_offset = MapLinker::DeltaMaker
        send(POSITION_LOADERS[side], map, offset, maker_offset)
      end

      # Get a tile from the map
      # @param x [Integer] real world x position
      # @param y [Integer] real world y position
      # @param z [Integer] z
      def [](x, y, z)
        @data[x + @offset_x, y + @offset_y, z]
      end

      # Draw the tile on the right layer
      # @param x [Integer] real world x of the top left tile
      # @param y [Integer] real world y of the top left tile
      # @param tx [Integer] x index of the tile to draw from top left tile (0)
      # @param ty [Integer] y index of the tile to draw from top left tile (0)
      # @param tz [Integer] z index of the tile to draw
      # @param layers [Array<Array<SpriteMap>>] layers of the tilemap .dig(priority, ty)
      def draw(x, y, tx, ty, tz, layers)
        tile_id = self[x + tx, y + ty, tz]
        return unless tile_id && tile_id != 0

        priority = @priorities[tile_id] || 0
        if tile_id < 384 # Autotile
          layer.dig(priority, ty).set(tx, autotiles_bmp[tile_id / 48 - 1],
                                      @rect.set((tile_id % 48) * 32, @autotile_counter[tile_id / 48]))
        else
          tile_id -= 384
          layer.dig(priority, ty).set(tx, @tilesets[0], # tile_id / 1024
                                      @rect.set(tile_id % 8 * 32, tile_id / 8 * 32)) # tile_id % 1024 / 8 * 32
        end
      end

      # Load the tileset
      def load_tileset
        # @type [RPG::Tileset]
        @tileset = $data_tilesets[@map.tileset_id]
        @priorities = @tileset.priorities
        load_tileset_graphics
      end

      private

      # Load the tileset graphics
      def load_tileset_graphics
        $game_temp.maplinker_map_id = map_id
        $game_temp.tileset_temp = @tileset.tileset_name
        Scheduler.start(:on_getting_tileset_name)
        name = $game_temp.tileset_name || @tileset.tileset_name
        $game_temp.tileset_name = nil

        # @type [Array<Bitmap>]
        # TODO: Add split loading of the tileset that way :
        #   1. load the image (if not chunked)
        #   2. split it in chunk of 256x1024 named this way tilesename-chunk_id
        #   3. save chunks in Yuki::VD and chunk names in MapData.tileset_chunks[tileset_name]
        #   4. return the chunk names
        #   Final result : @tilesets = (MapData.tileset_chunks[tileset_name] || load_chunks(tileset_name))
        #                              .map { |filename| RPG::Cache.tileset(filename) }
        @tilesets = [RPG::Cache.tileset(name)]
        # @type [Array<Bitmap>]
        @autotiles = @tileset.autotile_names.map { |aname| RPG::Cache.autotile(aname + '_._tiled') }
        @autotile_counter = Array.new(@autotiles.size + 1, 0)
      end

      # Load the position when map is on north
      # @param map [RPG::Map] current map
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      # @param maker_offset [Integer]
      def load_position_north(map, offset, maker_offset)
        @offset_x = -offset
        @offset_y = @map.height - maker_offset
        @x_range = offset...(offset + @map.width)
        @y_range = -@offset_y...0
      end

      # Load the position when map is on south
      # @param map [RPG::Map] current map
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      # @param maker_offset [Integer]
      def load_position_south(map, offset, maker_offset)
        @offset_x = -offset
        @offset_y = -map.height + maker_offset
        @x_range = offset...(offset + @map.width)
        @y_range = map.height...(map.height + @map.height - maker_offset)
      end

      # Load the position when map is on east
      # @param map [RPG::Map] current map
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      # @param maker_offset [Integer]
      def load_position_east(map, offset, maker_offset)
        @offset_x = -map.width + maker_offset
        @offset_y = -offset
        @x_range = map.width...(map.width + @map.width - maker_offset)
        @y_range = offset...(offset + @map.height)
      end

      # Load the position when map is on east
      # @param map [RPG::Map] current map
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      # @param maker_offset [Integer]
      def load_position_west(map, offset, maker_offset)
        @offset_x = @map.width - maker_offset
        @offset_y = -offset
        @x_range = -@offset_x...0
        @y_range = offset...(offset + @map.height)
      end

      # Load the position when map is the current one
      # @param map [RPG::Map] current map
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      # @param maker_offset [Integer]
      def load_position_self(map, offset, maker_offset)
        @offset_x = 0
        @offset_y = 0
        @x_range = 0...map.width
        @y_range = 0...map.height
      end
    end

  end
end
