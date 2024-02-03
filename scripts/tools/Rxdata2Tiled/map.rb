module Rxdata2Tiled
  class Map
    def initialize(filename, id, name, tilesets, tiled_tilesets, system_tags)
      # @type [RPG::Map]
      @map = load_data(filename)
      @id = id
      @name = name.downcase.gsub(/[^a-z0-9_]/, '_')
      # @type [RPG::Tileset]
      @tileset = tilesets[@map.tileset_id]
      @system_tags = system_tags[@map.tileset_id]
      # @type [Array<Tileset>]
      @tiled_tilesets = tiled_tilesets.dup
      init_tilesets
      init_layers
      convert
    end

    def convert
      data = @map.data
      @map.height.times do |y|
        @map.width.times do |x|
          3.times do |z|
            tile_id = data[x, y, z]

            next unless tile_id

            terrain_tag = @tileset.terrain_tags[tile_id] || 0
            passages = @tileset.passages[tile_id] || 0
            system_tag = @system_tags[tile_id] || 0
            @layers[-2].set(x, y, @tiled_tilesets[1].first_gid + system_tag - 384) if system_tag >= 384
            @layers[-3].set(x, y, @tiled_tilesets[0].first_gid + passages) if passages != 0
            @layers[-1].set(x, y, @tiled_tilesets[2].first_gid + terrain_tag) if terrain_tag != 0
            next if tile_id < 384

            priority = @tileset.priorities[tile_id] || 0
            @layers[priority * 3 + z].set(x, y, @tiled_tilesets[-1].first_gid + tile_id - 384)
          end
        end
      end
    end

    def to_tmx
      <<~EOTMX
      <?xml version="1.0" encoding="UTF-8"?>
      <map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" compressionlevel="0" width="#{@map.width}" height="#{@map.height}" tilewidth="32" tileheight="32" infinite="0" nextlayerid="22" nextobjectid="1">
        <editorsettings>
          <export format="tmx"/>
        </editorsettings>
        #{enum_tilesets_tmx}
      #{enum_layer_tmx}
      </map>
      EOTMX
    end

    def save
      filename = "Data/Tiled/Maps/rm_#{@id}_#{@name}.tmx"
      return if File.exist?(filename)

      @tiled_tilesets[-1].save
      File.write(filename, to_tmx)
    end

    def enum_tilesets_tmx
      @tiled_tilesets.map { |t| "<tileset firstgid=\"#{t.first_gid}\" source=\"#{t.relative_tsx_filename}\"/>" }.join("\n  ")
    end

    def enum_layer_tmx
      layers = @layers.select(&:touched)
      layers.map { |l| l.to_tsx }.join("\n")
    end

    def init_tilesets
      @tiled_tilesets << Tileset.new("graphics/tilesets/#{@tileset.tileset_name}.png", @tileset.name)
      first_gid = 1
      @tiled_tilesets.each do |t|
        t.first_gid = first_gid
        first_gid += t.tilecount
      end
    end

    def init_layers
      # @type [Array<Layer>]
      @layers = 6.times.flat_map do |i|
        3.times.map { |j| Layer.new(@map.width, @map.height, 1 + 3 * i + j, "layer_#{j+1}_priority_#{i+1}") }
      end
      @layers << Layer.new(@map.width, @map.height, 19, "passages")
      @layers << Layer.new(@map.width, @map.height, 20, "systemtags")
      @layers << Layer.new(@map.width, @map.height, 21, "terrain_tag")
    end

    class Layer
      # @return [Boolean]
      attr_reader :touched

      def initialize(width, height, id, name)
        @width = width
        @height = height
        @grid = height.times.map { Array.new(width, 0) }
        @touched = false
        @id = id
        @name = name
      end

      def set(x, y, tile_id)
        @touched = true
        @grid[y][x] = tile_id
      end

      def to_tsx
        data = @grid.map { |g| g.join(',') }.join(",\n")
<<~EOTSX
  <layer id="#{@id}" name="#{@name}" width="#{@width}" height="#{@height}">
    <data encoding="csv">
#{data}
    </data>
  </layer>
EOTSX
      end
    end
  end
end
