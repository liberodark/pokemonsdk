# Module that helps to convert stuff
module Converter
  module_function

  # Convert an autotile file to a specific autotile file
  # @param filename [String]
  # @example Converter.convert_autotile("Graphics/autotiles/eauca.png")
  def convert_autotile(filename)
    autotiles = [Image.new(filename)]
    bmp_arr = Array.new(48) { |i| generate_autotile_bmp(i + 48, autotiles) }
    bmp = Image.new(48 * 32, bmp_arr.first.height)
    bmp_arr.each_with_index do |sub_bmp, i|
      bmp.blt(32 * i, 0, sub_bmp, sub_bmp.rect)
    end
    bmp.to_png_file(new_filename = filename.gsub('.png', '_._tiled.png'))
    bmp.dispose
    bmp_arr.each(&:dispose)
    autotiles.first.dispose
    log_info("#{filename} converted to #{new_filename}!")
  end

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
  # Generate one tile of an autotile
  # @param id [Integer] id of the tile
  # @param autotiles [Array<Texture>] autotiles bitmaps
  # @return [Texture] the calculated bitmap
  def generate_autotile_bmp(id, autotiles)
    autotile = autotiles[id / 48 - 1]
    return Image.new(32, 32) if !autotile or autotile.width < 96

    src = SRC
    id %= 48
    tiles = Autotiles[id >> 3][id & 7]
    frames = autotile.width / 96
    bmp = Image.new(32, frames * 32)
    frames.times do |x|
      anim = x * 96
      4.times do |i|
        tile_position = tiles[i] - 1
        src.set(tile_position % 6 * 16 + anim, tile_position / 6 * 16, 16, 16)
        bmp.blt(i % 2 * 16, i / 2 * 16 + x * 32, autotile, src)
      end
    end
    return bmp
  end
end
