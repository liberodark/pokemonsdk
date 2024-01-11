module Tiled2Rxdata
  # Entity describing a specific Map Tile (animated or not)
  class Tile
    RECT_NORMAL = Rect.new(0, 0, 32, 32)
    RECT_VERT = Rect.new(0, 0, 1, 32)
    RECT_HORIZ = Rect.new(0, 0, 32, 1)
    BUFFER_IMAGES = [Image.new(32, 32), Image.new(32, 32)]

    # ID of the tile in the map
    # @return [Integer]
    attr_reader :id

    # All the sub tile of the map tile (eg. Tiled tile)
    # @return [Array<Sub>]
    attr_reader :subs

    # Attribute for RMXP tileset conversion
    attr_reader :passage, :system_tag, :priority, :terrain_tag

    # Create a new Map Tile
    # @param tile_data [Array<Hash>]
    # @param id [Integer]
    def initialize(tile_data, id)
      @id = id
      # @type [Array<Sub>]
      @subs = tile_data.select { |i| i[:globalId] }.map { |i| Sub.new(i[:globalId], i[:transformId]) }
      @passage = 0
      @system_tag = 0
      @priority = 0
      @terrain_tag = 0
      load_tileset_properties(tile_data)
    end

    # Test if the tile is animated
    # @param animated_tiles [GidAnimatedTiles]
    # @return [Boolean]
    def is_animated?(animated_tiles)
      return @subs.any? { |s| animated_tiles.is_tile_animated?(s.gid) }
    end

    # Draw the tile (as a static tile)
    # @param index [Integer]
    # @param image [Image]
    # @param tilesets [Array<Map::Tileset>]
    def draw(index, image, tilesets)
      @subs.each_with_index do |tile, i|
        tileset = tilesets.find { |i| tile.gid >= i.gid }
        next unless tileset

        draw_tile(index, image, tile, tileset, i == 0)
      end
    end

    # Draw the tile (as an animated tile)
    # @param index [Integer]
    # @param image [Image]
    # @param tilesets [Array<Map::Tileset>]
    # @param animated_tiles [GidAnimatedTiles]
    # @param animated_counter [Array<Yuki::Tilemap::MapData::AnimatedTileCounter>]
    def draw_animated(index, image, tilesets, animated_tiles, animated_counter)
      @subs.each_with_index do |tile, i|
        tileset = tilesets.find { |i| tile.gid >= i.gid }
        next unless tileset

        frames = animated_tiles.get_frames(tile)
        if frames
          draw_animated_column(index, image, frames, tile, tileset, i == 0)
          register_animated_counter(index, frames, animated_counter)
        else
          draw_column(index, image, tile, tileset, i == 0)
        end
      end
    end

    private

    # Draw the tile to the tileset
    # @param index [Integer]
    # @param image [Image]
    # @param tile [Sub]
    # @param tileset [Map::Tileset]
    # @param is_first [Boolean]
    def draw_tile(index, image, tile, tileset, is_first)
      id = tile.gid - tileset.gid
      src = tileset.image
      src_w = src.width / 32
      d_x = (index % 8) * 32
      d_y = (index / 8) * 32
      s_x = (id % src_w) * 32
      s_y = (id / src_w) * 32
      draw_to_image(image, tile, src, d_x, d_y, s_x, s_y, is_first)
    end

    # Draw the tile to an image
    # @param image [Image]
    # @param tile [Sub]
    # @param src [Image]
    # @param d_x [Integer]
    # @param d_y [Integer]
    # @param s_x [Integer]
    # @param s_y [Integer]
    # @param is_first [Boolean]
    def draw_to_image(image, tile, src, d_x, d_y, s_x, s_y, is_first)
      rect = RECT_NORMAL.set(s_x, s_y)
      if !tile.flipped_horizontally && !tile.flipped_vertically
        draw_to_final_image(image, d_x, d_y, src, rect, is_first)
      else
        BUFFER_IMAGES.first.blt!(0, 0, src, rect)
        if tile.flipped_vertically
          flip_vertical
          BUFFER_IMAGES.reverse!
        end
        if tile.flipped_horizontally
          flip_horizontally
          BUFFER_IMAGES.reverse!
        end
        draw_to_final_image(image, d_x, d_y, BUFFER_IMAGES.first, RECT_NORMAL.set(0, 0), is_first)
      end
    end

    # Draw the tile to an image
    # @param image [Image]
    # @param d_x [Integer]
    # @param d_y [Integer]
    # @param src [Image]
    # @param is_first [Boolean]
    def draw_to_final_image(image, d_x, d_y, src, rect, is_first)
      if is_first
        image.blt!(d_x, d_y, src, rect)
      else
        image.blt(d_x, d_y, src, rect)
      end
    end

    # Draw a static tile to a column of the autotile
    # @param index [Integer]
    # @param image [Image]
    # @param tile [Sub]
    # @param tileset [Map::Tileset]
    # @param is_first [Boolean]
    def draw_column(index, image, tile, tileset, is_first)
      id = tile.gid - tileset.gid
      src = tileset.image
      src_w = src.width / 32
      d_x = (index % 32) * 32
      s_x = (id % src_w) * 32
      s_y = (id / src_w) * 32

      0.step(image.height - 1, 32) do |d_y|
        draw_to_image(image, tile, src, d_x, d_y, s_x, s_y, is_first)
      end
    end

    # Draw an animated tile to a column of the autotile
    # @param index [Integer]
    # @param image [Image]
    # @param frames [Array<GidAnimatedTiles::AnimatedTile::Frame>]
    # @param tile [Sub]
    # @param tileset [Map::Tileset]
    # @param is_first [Boolean]
    def draw_animated_column(index, image, frames, tile, tileset, is_first)
      src = tileset.image
      src_w = src.width / 32
      d_x = (index % 32) * 32
      frames.each_with_index do |frame, index|
        d_y = 32 * index
        id = frame.tile_id
        s_x = (id % src_w) * 32
        s_y = (id / src_w) * 32
        draw_to_image(image, tile, src, d_x, d_y, s_x, s_y, is_first)
      end
    end

    # Register the frame counter to use in Runtime to animate this tile
    # @param index [Integer]
    # @param frames [Array<GidAnimatedTiles::AnimatedTile::Frame>]
    # @param animated_counter [Array<Yuki::Tilemap::MapData::AnimatedTileCounter>]
    def register_animated_counter(index, frames, animated_counter)
      waits = frames.map { |f| (f.duration / MIN_MS).clamp(1, Float::INFINITY).to_i }
      counter = ANIMATED_COUNT_CACHE[waits]
      animated_counter[index] = counter || Yuki::Tilemap::MapData::AnimatedTileCounter.new(waits)
    end

    # Load the tileset properties of the current tile
    # @param tile_data [Array<Hash>]
    def load_tileset_properties(tile_data)
      tile_data.each do |i|
        if i[:passage]
          @passage = i[:passage]
        elsif i[:systemTag]
          @system_tag = i[:systemTag]
        elsif i[:priority]
          @priority = i[:priority]
        elsif i[:terrainTag]
          @terrain_tag = i[:terrainTag]
        end
      end
    end

    # Flip the buffer image vertically
    def flip_vertical
      src, dst = BUFFER_IMAGES
      32.times do |y|
        dst.blt!(0, 31 - y, src, RECT_HORIZ.set(0, y))
      end
    end

    # Flip the buffer image Horizontally
    def flip_horizontally
      src, dst = BUFFER_IMAGES
      32.times do |x|
        dst.blt!(31 - x, 0, src, RECT_VERT.set(x))
      end
    end

    # Entity equivalent to an actual Tiled tile
    class Sub
      # Global ID of the tile in the map
      # @return [Integer]
      attr_reader :gid

      # If the tile is flipped horizontally in tiled
      # @return [Boolean]
      attr_reader :flipped_horizontally

      # If the tile is flipped vertically in tiled
      # @return [Boolean]
      attr_reader :flipped_vertically

      # If the tile is flipped diagonally in tiled (No clue about that)
      # @return [Boolean]
      attr_reader :flipped_diagonally

      # Create a new tiled tile
      # @param gid [Integer]
      # @param transform_id [Integer]
      def initialize(gid, transform_id)
        @gid = gid
        @flipped_horizontally = transform_id.anybits?(0x8)
        @flipped_vertically = transform_id.anybits?(0x4)
        @flipped_diagonally = transform_id.anybits?(0x2)
      end
    end
  end
end
