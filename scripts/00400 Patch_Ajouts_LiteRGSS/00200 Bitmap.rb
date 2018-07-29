#encoding: utf-8

# Class that describe a 2D matrix of color pixels.
class Bitmap
  # All the accepted bitmap extensions
  Exts = [".png", ".PNG", ".jpg", ".JPG"]
  # Original Bitmap.new function
  alias initialize_copy initialize
  # Initialize the bitmap, add automatically the extension to the filename
  # @param fn [String] Filename or FileData
  # @param from_mem [Boolean] load the file from memory (then filename is FileData)
  def initialize(fn, from_mem = false)
    if(from_mem)
      initialize_copy(fn, from_mem)
    else
      Exts.each do |i|
        fn2 = fn+i
        if(File.exist?(fn2))
          return initialize_copy(fn2)
        end
      end
      initialize_copy(fn)
    end
  end
  class << self
    # Encode all the PNG files of a directory to LodePNG files
    # @param path [String] the path to the directory
    def encode_path(path)
      path += '/' if path[-1] != '/'
      Dir["#{path}*.png"].each do |filename|
        bmp = Bitmap.new(filename)
        bmp.to_png_file(filename)
        bmp.dispose
        puts "#{filename} encoded..."
      end
    end
  end
  # Clear the bitmap surface
  def clear
    clear_rect(0, 0, self.width, self.height)
  end
end
