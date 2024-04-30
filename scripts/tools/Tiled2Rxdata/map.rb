module Tiled2Rxdata
  # Entity describing a tiled map ready to be converted
  class Map
    # Create a new map from the Studio data (JSON symbolize_names)
    # @param hash [Hash]
    def initialize(hash)
      # @type [Array<Tile>]
      @tiles = hash[:tileMetadata][:tileByTileId].map.with_index { |i, index| Tile.new(i, index) }
      # @type [Array<Hash>]
      @tilesets = hash[:tileMetadata][:tilesets]
      # @type [Array<Array<Integer>>]
      @layer_data = hash[:tileMetadata][:layerData]
      # @type [Integer]
      @width = hash[:tileMetadata][:width]
      # @type [Integer]
      @height = hash[:tileMetadata][:height]
      # @type [RPG::AudioFile]
      @bgm = RPG::AudioFile.new(hash[:bgm][:name], hash[:bgm][:volume], hash[:bgm][:pitch])
      # @type [RPG::AudioFile]
      @bgs = RPG::AudioFile.new(hash[:bgs][:name], hash[:bgs][:volume], hash[:bgs][:pitch])
      # @type [Integer]
      @encounter_step = hash[:stepsAverage]
      # @type [Integer]
      @id = hash[:id]
    end

    # Convert the map to RMXP data
    def convert
      load
      build_translator
      build_table
      build_tileset
      save
    end

    private

    # Filename of the map
    # @return [String]
    def filename
      return format('Data/Map%03d.rxdata', @id)
    end

    # Load the RMXP map or create a new one
    def load
      fn = filename
      # @type [RPG::Map]
      @data = File.exist?(fn) ? load_data(fn) : RPG::Map.new(@width, @height)
    end

    # Save the map to RMXP Map
    def save
      update_map_meta
      File.binwrite(filename, Marshal.dump(@data))
    end

    # Update the map metadata according to studio info
    def update_map_meta
      @data.bgm = @bgm
      @data.autoplay_bgm = !@bgm.name.empty?
      @data.bgs = @bgs
      @data.autoplay_bgs = !@bgs.name.empty?
      @data.encounter_step = @encounter_step
      @data.width = @width
      @data.height = @height
    end

    # Build the TileID => RMXP Tile ID translator
    def build_translator
      @gid_animated_tiles = GID_ANIMATED_TILES[@tilesets]
      # @type [Array<Tile>]
      @valid_tiles = @tiles.reject { |i| i.is_animated?(@gid_animated_tiles) }
      # @type [Array<Tile>]
      @animated_tiles = @tiles - @valid_tiles
      # @type [Hash{ Integer => Integer }]
      @translator = @valid_tiles.map.with_index { |i, index| [i.id, index + 384] }.to_h
      @translator.merge!(@gid_animated_tiles.build_animated_tiles_translator(@animated_tiles))
      @translator.default = 0
    end

    # Build the map internal table
    def build_table
      tbl = Table.new(@width, @height, 3)
      tbl.ysize.times do |y|
        offset = y * @width
        tbl.xsize.times do |x|
          @layer_data[offset + x].each_with_index do |id, index|
            tbl[x, y, index] = @translator[id]
          end
        end
      end
      @data.data = tbl
    end

    # Build the tileset metadata & graphics
    def build_tileset
      tileset_id = Settings.get.tileset_id(@id)
      @data.tileset_id = tileset_id
      tileset = TILESETS[tileset_id]
      map_info = MAP_INFO.find { |map| map[0] == @id }
      tileset.name = map_info[1].name if map_info
      tileset.tileset_name = "_#{tileset_id}"
      tileset.autotile_names = Array.new(8, '')
      tileset.passages = passages = Table.new(384 + @translator.size)
      tileset.priorities = priorities = Table.new(passages.xsize)
      tileset.terrain_tags = terrain_tags = Table.new(passages.xsize)
      SYSTEM_TAGS[tileset_id] = system_tags = Table.new(passages.xsize)

      @tiles.each do |tile|
        id = @translator[tile.id]
        next if id == 0

        passages[id] = tile.passage
        priorities[id] = tile.priority
        terrain_tags[id] = tile.terrain_tag
        system_tags[id] = tile.system_tag
      end
      priorities[0] = 5
      passages[0] = 0

      preloaded_tilesets = @tilesets.map { |i| Tileset.new(i) }.sort_by(&:gid).reverse
      build_tileset_image(tileset.tileset_name, preloaded_tilesets)
      build_autotile_images(tileset, preloaded_tilesets)
    end

    # Build the tileset graphics
    # @param filename [String]
    # @param preloaded_tilesets [Array<Tileset>]
    def build_tileset_image(filename, preloaded_tilesets)
      width = 256
      height = (@valid_tiles.size / 8.0).ceil * 32
      image = Image.new(width, height)
      @valid_tiles.each_with_index { |tile, index| tile.draw(index, image, preloaded_tilesets) }
      image.to_png_file("graphics/tilesets/#{filename}.png")
    end

    # Build the autotile images
    # @param tileset [RPG::Tileset]
    # @param preloaded_tilesets [Array<Tileset>]
    def build_autotile_images(tileset, preloaded_tilesets)
      groups = @animated_tiles.group_by { |t| (@translator[t.id] || 48) / 48 }
      groups.each do |index, tiles|
        frames = @gid_animated_tiles.count_frames(tiles[0])
        filename = "_#{@id}_#{index}"
        animated_counter = ANIMATED_COUNTS[filename] || []
        image = Image.new(tiles.size * 32, frames * 32)
        tiles.each_with_index { |tile, i| tile.draw_animated(i, image, preloaded_tilesets, @gid_animated_tiles, animated_counter) }
        image.to_png_file("graphics/autotiles/#{filename}.png")
        tileset.autotile_names[index - 1] = filename
        ANIMATED_COUNTS[filename] = animated_counter
      end
    end

    # Entity describing a Tiled tileset
    class Tileset
      # First GID of the tileset tiles in the Tiled Map
      # @return [Integer]
      attr_reader :gid

      # Create a new tileset
      # @param tileset_data [Hash]
      def initialize(tileset_data)
        @gid = tileset_data[:firstGlobalId]
        @filename, trans = tileset_filename_from_tsx(tileset_data[:source])
        @transparency = trans && Color.new(trans[0...2].to_i(16), trans[2...4].to_i(16), trans[4...6].to_i(16))
      end

      # Get the tileset image
      # @return [Image]
      def image
        return @image ||= get_tileset_image(@filename)
      end

      # Figure out the tileset source filename from TSX filename
      # @return [Array(String, String)]
      def tileset_filename_from_tsx(filename)
        data = ANIMATED_TILES[filename[3..].to_sym]
        return filename, nil unless source = data&.[](:assetSourceInTileset)

        return File.join('Data/Tiled/Maps', File.dirname(filename), source), data[:transparency]
      end

      # Get the tileset image from cache or load it to get it
      # @param filename [String]
      # @return [Image]
      def get_tileset_image(filename)
        unless image = LOADED_TILESET_IMAGES[filename]
          image = Image.new(filename)
          image.create_mask(@transparency, 0) if @transparency
          LOADED_TILESET_IMAGES[filename] = image
        end
        return image
      end
    end
  end
end
