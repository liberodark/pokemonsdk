module Yuki
  # Class responsive of displaying the map
  class Tilemap
    # Get all the map data used by the tilemap
    # @return [Array<Yuki::Tilemap::MapData>]
    attr_reader :map_datas
    # Get the ox
    # @return [Integer]
    attr_accessor :ox
    # Get the oy
    # @return [Integer]
    attr_accessor :oy

    # Create a new Tilemap
    # @param viewport [LiteRGSS::Viewport]
    def initialize(viewport)
      @viewport = viewport
      create_sprites
      @disposed = false
      @map_datas = []
      @ox = 0
      @oy = 0
      @autotile_idle_count = PSDK_CONFIG.tilemap.autotile_idle_frame_count
      reset
    end

    # Reset the tilemap in order to force it to draw the frame
    def reset
      @last_x = @last_y = @last_ox = @last_oy = nil
    end

    # Update the tilemap
    def update
      return if @disposed

      # ox / 32 = first visible tile (x), oy / 32 first visible tile (y)
      ox = (@ox.round >> 1 << 1)
      oy = (@oy.round >> 1 << 1)
      x = ox / 32 - 1
      y = oy / 32 - 1

      if x != @last_x || y != @last_y || (Graphics.frame_count % @autotile_idle_count == 0)
        draw(@last_x = x, @last_y = y)
        update_position(ox % 32, oy % 32)
      elsif ox != @last_ox || oy != @last_oy
        update_position(ox % 32, oy % 32)
      end

      @last_ox = ox
      @last_oy = oy
    end

    # Is the tilemap disposed
    # @return [Boolean]
    def disposed?
      return @disposed
    end

    # Set the map datas
    # @param map_datas [Array<Yuki::Tilemap::MapData>]
    def map_datas=(map_datas)
      @map_datas.clear
      @map_datas.concat(map_datas.select { |data| data.is_a?(MapData) })
      reset
    end

    private

    # Generate the sprites of the tilemap with the right settings
    # @param tile_size [Integer] the dimension of a tile
    # @param zoom [Numeric] the global zoom of a tile
    def create_sprites(tile_size = 32, zoom = 1)
      viewport = @viewport
      # Variable allowing to quicky update the sprites
      @all_sprites = []
      # Variable containing the sprite (in a way it's easier to access)
      @sprites = []
      nx, ny = nx_ny_configs
      3.times do
        priority_array = Array.new(6) do
          priority_layer = Array.new(ny) do |y|
            sprite = SpriteMap.new(viewport, tile_size, nx)
            sprite.set_position(-tile_size, (y - 1) * tile_size)
            sprite.tile_scale = zoom
            sprite.z = 0
            @all_sprites << sprite
            next(sprite)
          end
          next(priority_layer)
        end
        @sprites << priority_array
      end
      @nx = nx
      @ny = ny
    end

    # Get the tilemap configuration for its size
    # @return [Array<Integer>]
    def nx_ny_configs
      return PSDK_CONFIG.tilemap.tilemap_size_x, PSDK_CONFIG.tilemap.tilemap_size_y
    end

    # Update the position of each tile according to the ox / oy, also adjusts z
    # @param ox [Integer] ox of every tiles
    # @param oy [Integer] oy of every tiles
    def update_position(ox, oy)
      add_z = oy / 2
      @sprites.each do |layer|
        layer.each_with_index do |priority_layer, priority|
          priority_layer.each_with_index do |sprite, py|
            sprite.set_origin(ox, oy)
            sprite.z = (py + priority) * 32 - add_z if priority > 0
          end
        end
      end
    end

    # Draw the tiles
    # @param x [Integer] real world x of the top left tile
    # @param y [Integer] real world y of the top left tile
    def draw(x, y)
      @all_sprites.each(&:reset)
      maps = map_datas
      @sprites.each_with_index do |layer, tz|
        @ny.times do |ty|
          ry = ty + y
          @nx.times do |tx|
            rx = tx + x
            # @type [Yuki::Tilemap::MapData]
            map = maps.find { |data| data.x_range.include?(rx) && data.y_range.include?(ry) }
            map&.draw(x, y, tx, ty, tz, layer)
          end
        end
      end
    end
  end

  class Tilemap16px < Tilemap
    private

    # Generate the sprites of the tilemap with the right settings
    # @param tile_size [Integer] the dimension of a tile
    # @param zoom [Numeric] the global zoom of a tile
    def create_sprites(tile_size = 16, zoom = 0.5)
      super(tile_size, zoom)
    end
  end
end
