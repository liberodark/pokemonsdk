module Tiled2Rxdata
  # Entity loading all the animated tiles tied to a set of tileset
  # It helps greatly to translate a map tile to animated tile when needed (same GID)
  class GidAnimatedTiles
    # @return [Array<Hash>]
    attr_reader :map_tilesets

    # Initialize the GID Animated Tiles
    # @param animated_tiles [Hash]
    # @param map_tilesets [Array<Hash>]
    def initialize(animated_tiles, map_tilesets)
      @map_tilesets = map_tilesets
      # @type [Array<AnimatedTile>]
      @tiles = map_tilesets.flat_map do |i|
        source = i[:source][3..]
        tiles = animated_tiles[source.to_sym]
        next [] unless tiles

        offset = i[:firstGlobalId]
        next tiles[:animatedTiles].map { |j| AnimatedTile.new(j[:tileId] + offset, j[:frames]) }
      end

      # @type [Hash{Integer => AnimatedTile}]
      @tiles_by_id = @tiles.map { |i| [i.gid, i] }.to_h
    end

    # Test if a gid is an animated tile
    # @param gid [Integer]
    # @return [Boolean]
    def is_tile_animated?(gid)
      return @tiles_by_id.key?(gid)
    end

    # Build the GID => RMXP Tile ID translator for all the given animated tiles
    # @param tiles [Array<Tile>]
    def build_animated_tiles_translator(tiles)
      # @type {Hash{Integer => Array<Tile>}}
      groups = tiles.group_by { |tile| count_frames(tile) }
      assert_group_valid(groups.values)

      # @type [Array<Array<Tile>>]
      tiles_by_autotiles = groups.values.map { |v| v.group_by.with_index { |_k, i| i / 32 }.values }.flatten(1)
      return tiles_by_autotiles.flat_map.with_index { |a, i| a.map.with_index { |t, j| [t.id, i * 48 + 48 + j] } }.to_h
    end

    # Assert that were not overflowing the number of RMXP autotiles & still be nice to weaker device by limiting texture to 1024px
    # @param tiles [Array<Array<Tile>>]
    def assert_group_valid(tiles)
      total_count = tiles.sum { |i| (i.size / 32.0).ceil * 32 }
      raise "[RMXP ERROR] This map has too many animated diverse tiles (#{total_count})" if total_count > 224 # 32 * 7
    end

    # Count the maximum number of frame of an animated tile from a map tile
    # @param [Tile]
    # @return [Integer]
    def count_frames(tile)
      tile.subs.map { |s| @tiles_by_id[s.gid]&.frames&.size || 0 }.max
    end

    # Get the frames of a sub Tile
    # @param s [Tile::Sub]
    # @return [Array<AnimatedTile::Frame>]
    def get_frames(s)
      @tiles_by_id[s.gid]&.frames
    end

    # Class describing an Animated tile by holding a GID meeting a tileset set condition
    class AnimatedTile
      # ID of the animated tile in the tileset set
      # @return [Integer]
      attr_reader :gid

      # Frames of the animate tile
      # @return [Array<Frame>]
      attr_reader :frames

      # Create a new AnimatedTile
      # @param gid [Integer]
      # @param frames [Array<Hash>]
      def initialize(gid, frames)
        @gid = gid
        @frames = frames.map { |f| Frame.new(f[:tileId], f[:duration]) }
      end

      # Frame of an animated tile
      class Frame
        # ID of the tile in the tileset it belongs to
        # @return [Integer]
        attr_reader :tile_id

        # Duration of the frame in ms
        # @return [Integer]
        attr_reader :duration

        # Create a new Frame
        # @param tile_id [Integer]
        # @param duration [Integer]
        def initialize(tile_id, duration)
          @tile_id = tile_id
          @duration = duration
        end
      end
    end
  end
end
