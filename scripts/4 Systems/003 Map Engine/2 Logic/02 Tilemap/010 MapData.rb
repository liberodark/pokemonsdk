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
      # Get the map id
      # @return [Integer]
      attr_reader :map_id
      # Get the map X coordinate range
      # @return [Range]
      attr_reader :x_range
      # Get the map Y coordinate range
      # @return [Range]
      attr_reader :y_range
      # Get the map offset_x
      # @return [Integer]
      attr_reader :offset_x
      # Get the map offset_y
      # @return [Integer]
      attr_reader :offset_y
      # Get the tileset filename (to prevent unwanted dispose in the future)
      # @return [String]
      attr_reader :tileset_name
      # Get the side of the map
      # @return [Symbol]
      attr_reader :side

      # Variable containing tileset chunks
      @tileset_chunks = {}

      # Create a new MapData
      # @param map [RPG::Map]
      # @param map_id [Integer]
      def initialize(map, map_id)
        @data = map.data
        @map = map
        @map_id = map_id
        @rect = Rect.new(0, 0, 32, 32)
      end

      # Sets the position of the map in the 2D Space
      # @param map [RPG::Map] current map
      # @param side [Symbol] which side the map is (:north, :south, :east, :west)
      # @param offset [Integer] offset relative to the side of the map in the positive perpendicular position
      def load_position(map, side, offset)
        maker_offset = MapLinker::DELTA_MAKER
        send(POSITION_LOADERS[side], map, offset, maker_offset)
        @side = side
      end

      # Get a tile from the map
      # @param x [Integer] real world x position
      # @param y [Integer] real world y position
      # @param z [Integer] z
      def [](x, y, z)
        @data[x + @offset_x, y + @offset_y, z]
      end

      # Set tile sprite to sprite
      # @param sprite [Sprite]
      # @param tile_id [Integer] ID of the tile the sprite wants
      def assign_tile_to_sprite(sprite, tile_id)
        tile_id -= 384
        sprite.bitmap = @tilesets[tile_id / 256]
        sprite.src_rect.set(tile_id % 8 * 32, (tile_id % 256) / 8 * 32, 32, 32)
      end

      # Draw the tile on the right layer
      # @param x [Integer] real world x of the top left tile
      # @param y [Integer] real world y of the top left tile
      # @param tx [Integer] x index of the tile to draw from top left tile (0)
      # @param ty [Integer] y index of the tile to draw from top left tile (0)
      # @param tz [Integer] z index of the tile to draw
      # @param layer [Array<Array<SpriteMap>>] layers of the tilemap .dig(priority, ty)
      def draw(x, y, tx, ty, tz, layer)
        tile_id = self[x + tx, y + ty, tz]
        return unless tile_id && tile_id != 0

        priority = @priorities[tile_id] || 0
        if tile_id < 384 # Autotile
          tileset = @autotiles[tile_id / 48 - 1]
          src_x = tile_id % 48
          src_y = @animated_tile_counters[tile_id / 48 - 1][src_x]&.count || 0
          tileset && layer.dig(priority, ty).set(tx, tileset, @rect.set(src_x * 32, src_y * 32))
        else
          tile_id -= 384
          tileset = @tilesets[tile_id / 256]
          tileset && layer.dig(priority, ty).set(tx, tileset, @rect.set(tile_id % 8 * 32, (tile_id % 256) / 8 * 32))
        end
      end

      # Draw the visible part of the map
      # @param x [Integer] real world x of the top left tile
      # @param y [Integer] real world y of the top left tile
      # @param rx [Integer] real world x of the bottom right tile
      # @param ry [Integer] real world y of the bottom right tile
      # @param layers [Array<Array<Array<SpriteMap>>>] layers of the tilemap .dig(tz, priority, ty)
      def draw_map(x, y, rx, ry, layers)
        lx = x_range.min
        mx = x_range.max
        ly = y_range.min
        my = y_range.max

        bx = lx > x ? lx : x
        ex = mx > rx ? rx : mx
        by = ly > y ? ly : y
        ey = my > ry ? ry : my
        return unless bx <= ex && by <= ey

        bx.upto(ex) do |ax|
          by.upto(ey) do |ay|
            layers.each_with_index do |layer, tz|
              draw(x, y, ax - x, ay - y, tz, layer)
            end
          end
        end
      end

      # Load the tileset
      def load_tileset
        # @type [RPG::Tileset]
        @tileset = $data_tilesets[@map.tileset_id]
        @priorities = @tileset.priorities
        load_tileset_graphics
      end

      # Update the autotiles counter (for tilemap)
      def update_counters
        @unique_counters.each(&:update)
        AnimatedTileCounter.last_update_counter_time = Graphics.current_time
      end

      private

      # Load the tileset graphics
      def load_tileset_graphics
        $game_temp.maplinker_map_id = @map_id
        $game_temp.tileset_temp = @tileset.tileset_name
        Scheduler.start(:on_getting_tileset_name)
        name = $game_temp.tileset_name || @tileset.tileset_name
        $game_temp.tileset_name = nil

        # @type [Array<Texture>]
        # TODO: Add split loading of the tileset that way :
        #   1. load the image (if not chunked)
        #   2. split it in chunk of 256x1024 named this way tilesename-chunk_id
        #   3. save chunks in Yuki::VD and chunk names in MapData.tileset_chunks[tileset_name]
        #   4. return the chunk names
        #   Final result : @tilesets = (MapData.tileset_chunks[tileset_name] || load_chunks(tileset_name))
        #                              .map { |filename| RPG::Cache.tileset(filename) }
        @tilesets = load_tileset_chunks(@tileset_name = name)
        # @type [Array<Texture>]
        @autotiles = @tileset.autotile_names.map { |aname| MapLinker.spriteset.load_autotile(aname) }
        load_counters
      end

      def load_counters
        # @type [Array<Array<Yuki::Tilemap::MapData::AnimatedTileCounter>>]
        @animated_tile_counters = @tileset.autotile_names.map.with_index do |aname, index|
          $data_animated_tiles[aname] || AnimatedTileCounter.defaults(@autotiles[index], aname)
        end
        # @type [Array<Yuki::Tilemap::MapData::AnimatedTileCounter>]
        @unique_counters = @animated_tile_counters.flatten.uniq
      end

      # Load tileset chunks
      # @param name [Filename]
      # @return [Array<Texture>]
      def load_tileset_chunks(name)
        chunks = MapData.tileset_chunks[name]
        chunks&.compact!
        return chunks if chunks&.none?(&:disposed?)

        return (MapData.tileset_chunks[name] = [RPG::Cache.default_bitmap]) unless RPG::Cache.tileset_exist?(name)

        image = RPG::Cache.tileset_image(name)
        working_surface = Image.new(256, 1024)
        rect = Rect.new(256, 1024)
        chunks = (image.height / 1024.0).ceil.times.map do |i|
          height = ((i + 1) * 1024) > image.height ? image.height - (i * 1024) : 1024
          working_surface.blt!(0, 0, image, rect.set(0, i * 1024, 256, height))
          bmp = Texture.new(256, 1024)
          working_surface.copy_to_bitmap(bmp)
          next bmp
        end
        image.dispose
        working_surface.dispose
        return MapData.tileset_chunks[name] = chunks
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

      class << self
        # Get tileset chunks
        # @return [Hash{filename => Array<Texture>}]
        attr_reader :tileset_chunks
      end

      class AnimatedTileCounter
        # Hash of default AnimatedTileCounters
        DEFAULT_COUNTERS = {}

        # @return [Integer]
        attr_reader :count

        # @return [Array<Integer>]
        attr_reader :waits

        # @return [Time]
        attr_reader :last_update_time

        # Create a new animated tile counter
        # @param waits [Array<Integer>] list of number of frame to wait for each count
        def initialize(waits)
          @waits = waits
          @count = 0
          @waited_count = 0
        end

        # Update the count value
        def update
          # Tiny safety to prevent autotiles going wild when used in several maps
          return if Graphics.current_time == @last_update_time

          @last_update_time = Graphics.current_time
          @waited_count += 1
          if @waits[@count] <= @waited_count
            @count = (@count + 1) % @waits.size
            @waited_count = 0
          end
        end

        # Synchronize itself with another animated tile
        # @param animated_tile [AnimatedTileCounter]
        def synchronize(animated_tile)
          @count = animated_tile.count
        end

        class << self
          # Set or get the last update counter time
          attr_accessor :last_update_counter_time

          # Get the default counters for the specified texture
          # @param texture [Texture]
          # @param texture_name [String]
          # @return [Array<AnimatedTileCounter>]
          def defaults(texture, texture_name)
            default = DEFAULT_COUNTERS[texture_name]
            return default if default

            counter = new(Array.new((texture.height / 32).clamp(1, Float::INFINITY), 1))
            default = (0...48).map { counter }

            return DEFAULT_COUNTERS[texture_name] = default
          end

          # Synchronize all the counter based on their wait type
          def synchronize_all
            # @type [Array<Array<AnimatedTileCounter>>]
            @grouped_values ||= $data_animated_tiles.values.flatten.group_by { |i| i.waits }.values
            time = @last_update_counter_time
            @grouped_values.each do |group|
              sync_point = group.find { |i| i.last_update_time == time } || group[0]
              group.each { |animated_tile| animated_tile.synchronize(sync_point) }
            end
          end
        end
      end
    end
  end
end
