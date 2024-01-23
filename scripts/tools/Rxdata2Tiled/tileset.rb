module Rxdata2Tiled
  class Tileset
    SPECIAL_TILESETS = {
      passages: ['Data/Tiled/Assets/passages.png', 'passages', 'ff00ff'],
      systemtags: ['Data/Tiled/Assets/prio_w.png', 'systemtags', 'f05ba1'],
      terrain_tag: ['Data/Tiled/Assets/terrain_tag.png', 'terrain_tag', 'ff00ff'],
    }
    # @return [Integer]
    attr_reader :tilecount
    # @return [Integer]
    attr_accessor :first_gid

    def initialize(filename, name, trans = "ff00ff")
      @name = name.downcase.gsub(/[^a-z0-9_]/, '_')
      @origin_filename = filename
      @image_filename = filename.downcase.gsub('graphics/tilesets/', '../Assets/').gsub('data/tiled/assets/', '../Assets/')
      image = Image.new(filename)
      @width = image.width
      @height = image.height
      image.dispose
      @columns = @width / 32
      @tilecount = @height / 32 * @columns
      @trans = trans
    end

    def to_tsx
      <<~EOTSX
        <?xml version="1.0" encoding="UTF-8"?>
        <tileset version="1.2" tiledversion="1.3.0" name="#{@name}" tilewidth="32" tileheight="32" tilecount="#{@tilecount}" columns="#{@columns}">
          <image source="#{@image_filename}" trans="#{@trans}" width="#{@width}" height="#{@height}"/>
        </tileset>
      EOTSX
    end

    def relative_tsx_filename
      "../Tilesets/#{@name}.tsx"
    end

    def save
      filename = "Data/Tiled/Tilesets/#{@name}.tsx"
      return if File.exist?(filename)

      copy_image_to_assets
      File.write(filename, to_tsx)
    end

    def copy_image_to_assets
      target_filename = File.join('Data/Tiled/Tilesets', @image_filename)
      return if File.exist?(target_filename)

      IO.copy_stream(@origin_filename, target_filename)
    end
  end
end
