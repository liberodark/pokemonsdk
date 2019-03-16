#encoding: utf-8

# Draw the Map on screen
#   Each map can use a tileset using 8192 tiles (4 * 256 x 8192 / 32x32)
#     - Current map is from : 384 to 8575
#     - North map is from : 8576 to 16767
#     - South map is from : 16768 to 24959
#     - West map is from : -8192 to -1
#     - East map is from : -16384 to -8193
# @author Nuri Yuri
class Tilemap
  # Bitmap used as a tileset
  # @return [Bitmap]
  attr_accessor :tileset
  # Array of Bitmap used as autotiles
  # @return [Array<Bitmap>]
  attr_accessor :autotiles
  # The tiles on the map
  # @return [Table]
  attr_accessor :map_data
  # The "z" attribute of each tiles in the tileset
  # @return [Table]
  attr_accessor :priorities
  # The offset x of the Tilemap
  # @return [Integer]
  attr_accessor :ox
  # The offset y of the Tilemap
  # @return [Integer]
  attr_accessor :oy
  # The viewport where the tilemap is shown
  # @return [Viewport]
  attr_reader :viewport
  # If the tilemap has been freed
  # @return [Boolean]
  attr_reader :disposed
  # Number of frame before each autotile change their animation frame
  Autotile_Frame_Count = 6
  # The autotile builder data
  Autotiles = [
    [ [27, 28, 33, 34], [ 5, 28, 33, 34], [27,  6, 33, 34], [ 5,  6, 33, 34],
      [27, 28, 33, 12], [ 5, 28, 33, 12], [27,  6, 33, 12], [ 5,  6, 33, 12] ],
    [ [27, 28, 11, 34], [ 5, 28, 11, 34], [27,  6, 11, 34], [ 5,  6, 11, 34],
      [27, 28, 11, 12], [ 5, 28, 11, 12], [27,  6, 11, 12], [ 5,  6, 11, 12] ],
    [ [25, 26, 31, 32], [25,  6, 31, 32], [25, 26, 31, 12], [25,  6, 31, 12],
      [15, 16, 21, 22], [15, 16, 21, 12], [15, 16, 11, 22], [15, 16, 11, 12] ],
    [ [29, 30, 35, 36], [29, 30, 11, 36], [ 5, 30, 35, 36], [ 5, 30, 11, 36],
      [39, 40, 45, 46], [ 5, 40, 45, 46], [39,  6, 45, 46], [ 5,  6, 45, 46] ],
    [ [25, 30, 31, 36], [15, 16, 45, 46], [13, 14, 19, 20], [13, 14, 19, 12],
      [17, 18, 23, 24], [17, 18, 11, 24], [41, 42, 47, 48], [ 5, 42, 47, 48] ],
    [ [37, 38, 43, 44], [37,  6, 43, 44], [13, 18, 19, 24], [13, 14, 43, 44],
      [37, 42, 43, 48], [17, 18, 47, 48], [13, 18, 43, 48], [ 1,  2,  7,  8] ]
  ]
  # The source rect (to draw autotiles)
  SRC = Rect.new(0, 0, 16, 16)
  # Number of tiles drawn on X axis
  NX = 22
  # Number of tiles drawn on Y axis
  NY = 17
  # List of parsed Autotile bitmap by tile ID
  #@@autotile_bmp = Array.new(384)
  # List of unparsed Autotile bitmap (to detect autotile change)
  @@autotiles_copy = Array.new(7, -1)
  # Parsed Autotile bitmap database (to reduce autotile bitmap parsing)
  #@@autotile_db = Hash.new
  # Create a new Tilemap object
  # @param viewport [Viewport] the viewport where the Tilemap is shown
  def initialize(viewport)
    @viewport = viewport
    @autotiles = Array.new(7, RPG::Cache.default_bitmap)
    @autotiles_counter = Array.new(8, 0)
    @autotiles_copy = @@autotiles_copy
    #@autotiles_bmp = @@autotile_bmp
    make_sprites(viewport)
    check_copy(@autotiles_copy)
    @last_ox = @last_oy = nil #> Prévenir d'un déplacement inutile
    @disposed = false
    @map_linker = Yuki::MapLinker
  end
  # Force reset of the tilemap
  def reset
    @last_x = @last_y = @last_ox = @last_oy = nil
  end
  # Update the tilemap
  def update
    return if @disposed
    # ox / 32 = position du premier tile visible, oy / 32 pareil
    ox = (@ox.round >> 1 << 1)
    oy = (@oy.round >> 1 << 1)
    #> S'il y a une variation dans les autotiles
    if @autotiles != @autotiles_copy
      reload_autotiles
      draw_all(@last_x = ox / 32 - 1, @last_y = oy / 32 - 1, ox % 32, oy % 32)
    #> Si le compteur tombe sur le moment de mise à jour des autotiles
    elsif (Graphics.frame_count % Autotile_Frame_Count) == 0
      x = ox / 32 - 1
      y = oy / 32 - 1
      #> Si la position a changée il faut remettre les bitmaps où il faut
      if(x != @last_x or y != @last_y)
        update_autotile_counter(@autotiles_counter, @autotiles)
        draw_all(@last_x = x, @last_y = y, ox % 32, oy % 32)
      else
        draw_autotiles(@last_x = x, @last_y = y, ox % 32, oy % 32)
      end
    #> Si la map a bougée
    elsif ox != @last_ox or oy != @last_oy
      x = ox / 32 - 1
      y = oy / 32 - 1
      #> Si la position a changée il faut remettre les bitmaps où il faut
      if(x != @last_x or y != @last_y)
        draw_all(@last_x = x, @last_y = y, ox % 32, oy % 32)
      else
        update_positions(@last_x = x, @last_y = y, ox % 32, oy % 32)
      end
    end
    @last_ox = ox
    @last_oy = oy
  end
  # Update the autotile counter
  # @param autotiles_counter [Array<Integer>] counter for each autotiles
  # @param autotiles_bmp [Array<Bitmap>] bitmap for each autotiles
  def update_autotile_counter(autotiles_counter, autotiles_bmp)
    1.upto(7) do |index|
      counter = autotiles_counter[index]
      counter += 32
      counter = 0 if(autotiles_bmp[index - 1].height <= counter)#if(autotiles_bmp[index * 48].height <= counter)
      autotiles_counter[index] = counter
    end
  end
  # Draw only autotiles
  # @param x [Integer] position x of the first tile shown
  # @param y [Integer] position y of the first tile shown
  # @param ox [Integer] ox of every tiles
  # @param oy [Integer] oy of every tiles
  def draw_autotiles(x, y, ox, oy)
    map_data = @map_data
    autotiles_counter = @autotiles_counter
    autotiles_bmp = @autotiles
    add_z = oy / 2
    maplinker = @map_linker
    update_autotile_counter(autotiles_counter, autotiles_bmp)
    @sprites.each_with_index do |sprite_table, pz|
      sprite_table.each_with_index do |sprite_col, px|
        sprite_col.each_with_index do |sprite, py|
          sprite.ox = ox
          sprite.oy = oy
          tile_id = map_data[cx = x + px, cy = y + py, pz]
          next unless tile_id
          if tile_id.between?(1, 383) # Autotile
            sprite.src_rect.set((tile_id % 48) * 32, autotiles_counter[tile_id / 48], 32, 32)
          end
          priority = maplinker.get_priority(cx, cy)[tile_id] # -- priorities[tile_id]
          next(sprite.z = 0) if !priority or priority == 0
          sprite.z = (py + priority) * 32 - add_z
        end
      end
    end
  end
  # Draw everything
  # @param x [Integer] position x of the first tile shown
  # @param y [Integer] position y of the first tile shown
  # @param ox [Integer] ox of every tiles
  # @param oy [Integer] oy of every tiles
  def draw_all(x, y, ox, oy)
    # -- priorities = @priorities
    map_data = @map_data
    autotiles_counter = @autotiles_counter
    autotiles_bmp = @autotiles#@autotiles_bmp
    # -- tileset1 = @tileset
    max_size = 4096 # Graphics::MAX_TEXTURE_SIZE
    add_z = oy / 2
    maplinker = @map_linker
    @sprites.each_with_index do |sprite_table, pz|
      sprite_table.each_with_index do |sprite_col, px|
        sprite_col.each_with_index do |sprite, py|
          sprite.ox = ox
          sprite.oy = oy
          tile_id = map_data[cx = x + px, cy = y + py, pz]
          if(!tile_id or tile_id == 0)
            next(sprite.bitmap = nil)
          elsif(tile_id < 384) #Autotile
            sprite.bitmap = autotiles_bmp[tile_id / 48 - 1]
            sprite.src_rect.set((tile_id % 48) * 32, autotiles_counter[tile_id / 48], 32, 32)
          else #Tile
            sprite.bitmap = maplinker.get_tileset(cx, cy) # -- tileset1
            tid = tile_id - 384
            tlsy = tid / 8 * 32
            sprite.src_rect.set((tid % 8 + tlsy / max_size * 8) * 32, tlsy % max_size, 32, 32)
          end
          priority = maplinker.get_priority(cx, cy)[tile_id] # -- priorities[tile_id]
          next(sprite.z = 0) if !priority or priority == 0
          sprite.z = (py + priority) * 32 - add_z
        end
      end
    end

  end
  # Only change the ox, oy and z position of each tiles
  # @param x [Integer] position x of the first tile shown
  # @param y [Integer] position y of the first tile shown
  # @param ox [Integer] ox of every tiles
  # @param oy [Integer] oy of every tiles
  def update_positions(x, y, ox, oy)
    # -- priorities = @priorities
    map_data = @map_data
    add_z = oy / 2
    maplinker = @map_linker
    @sprites.each_with_index do |sprite_table, pz|
      sprite_table.each_with_index do |sprite_col, px|
        sprite_col.each_with_index do |sprite, py|
          sprite.ox = ox
          sprite.oy = oy
          tile_id = map_data[cx = x + px, cy = y + py, pz]
          next if !tile_id or tile_id <= 0
          priority = maplinker.get_priority(cx, cy)[tile_id] # -- priorities[tile_id]
          next if !priority or priority == 0
          sprite.z = (py + priority) * 32 - add_z
        end
      end
    end
=begin
    @sprites.each do |sprite_table|
      sprite_table.each do |sprite_col|
        sprite_col.each do |sprite|
          sprite.ox = ox
          sprite.oy = oy
        end
      end
    end
=end
  end
  # Free the tilemap
  def dispose
    return if @disposed
    @sprites.each { |sprite_array| sprite_array.each { |sprite_col| sprite_col.each { |sprite| sprite.dispose } } }
    @disposed = true
  end
  # If the tilemap is disposed
  # @return [Boolean]
  alias disposed? disposed
  private
  # Generate the sprites of the tilemap with the right settings
  # @param viewport [Viewport] the viewport where tiles are shown
  # @param tile_size [Integer] the dimension of a tile
  # @param zoom [Numeric] the global zoom of a tile
  def make_sprites(viewport, tile_size = 32, zoom = 1)
    sprite = nil
    @sprites = Array.new(3) do
      Array.new(NX) do |x|
        Array.new(NY) do |y|
          sprite = Sprite.new(viewport)
          sprite.x = (x - 1) * tile_size
          sprite.y = (y - 1) * tile_size
          sprite.zoom_x = sprite.zoom_y = zoom
          next(sprite)
        end
      end
    end
  end
  # Reload the autotiles (internal)
  def reload_autotiles
    autotiles = @autotiles
    autotiles_copy = @autotiles_copy
    7.times do |j|
      if autotiles_copy[j] != autotiles[j]
        autotiles_copy[j] = autotiles[j]
        #load_autotile(j, (j + 1) * 48, autotiles)
      end
    end
  end
  # Check if the old autotile Array is not the same
  # @param copy [Array]
  def check_copy(copy)
    7.times do |i|
      if copy[i] and copy[i] != -1
        if copy[i].disposed?
          @@autotiles_copy = @autotiles_copy = Array.new(7, -1)
        end
        break
      end
    end
  end
=begin
  # Load an autotile
  # @param j [Integer] index of the autotile on the autotile table
  # @param base_id [Integer] first id of the autotile tiles
  # @param autotiles [Array<Bitmap>] autotiles bitmaps
  def load_autotile(j, base_id, autotiles)
    autotile_name = $game_map.autotile_names[j]
    autotiles_bmp = @autotiles_bmp
    if(autotile_data = @@autotile_db[autotile_name])
      unless autotile_data.first.disposed?
        autotile_data.each_with_index do |autotile, i|
          autotiles_bmp[base_id + i] = autotile
        end
        return
      end
    end
    autotile_data = []
    base_id.upto(base_id + 47) do |i|
      autotile_data << (autotiles_bmp[i] = generate_autotile_bmp(i, autotiles))
    end
    @@autotile_db[autotile_name] = autotile_data
  end
  # Generate one tile of an autotile
  # @param id [Integer] id of the tile
  # @param autotiles [Array<Bitmap>] autotiles bitmaps
  # @return bmp [Bitmap] the calculated bitmap
  def generate_autotile_bmp(id, autotiles)
    autotile = autotiles[id / 48 - 1]
    return Bitmap.new(32, 32) if !autotile or autotile.width < 96
    src = SRC
    id %= 48
    tiles = Autotiles[id>>3][id&7]
    frames = autotile.width / 96
    bmp = Bitmap.new(32, frames * 32)
    frames.times do |x|
      anim = x * 96
      4.times do |i|
        tile_position = tiles[i] - 1
        src.set(tile_position % 6 * 16 + anim, tile_position / 6 * 16, 16, 16)
        bmp.blt(i % 2 * 16, i / 2 * 16 + x * 32, autotile, src)
      end
    end
    bmp.update
    return bmp
  end
=end
end
# PSDK Native resolution version the Tilemap
class Yuri_Tilemap < Tilemap
  # Generate the sprites of the tilemap with the right settings
  # @param viewport [Viewport] the viewport where tiles are shown
  def make_sprites(viewport)
    super(viewport, 16, 0.5)
  end
end
