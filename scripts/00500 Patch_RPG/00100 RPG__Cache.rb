#encoding: utf-8

# Script that cache bitmaps when they are reusable.
# @author Nuri Yuri
module RPG::Cache
  @default_bitmap = Bitmap.new(16,16)
  # Array of load methods to call when the game starts
  LOADS = Array.new
  # Common filename of the image to load
  Common_filename = 'Graphics/%s/%s'
  # Common filename with .png
  Common_filename_format = format('%s.png', Common_filename)
  # Notification message when an image is not found
  Notification_title = 'Ressource graphique introuvable'
  # Size of array description with 8bit encoded bitmaps
  Sizeof_8bit_bitmap_data = 5

  module_function
  # Gets the default bitmap
  # @note Should be used in scripts that require a bitmap be doesn't perform anything on the bitmap
  def default_bitmap
    @default_bitmap = Bitmap.new(16,16) if @default_bitmap.disposed?
    @default_bitmap
  end
  # Dispose every bitmap of a cache table
  # @param cache_tab [Hash{String => Bitmap}] cache table where bitmaps should be disposed
  def dispose_bitmaps_from_cache_tab(cache_tab)
    bitmap = nil
    cache_tab.each_value  { |bitmap| bitmap.dispose if bitmap && !bitmap.disposed? && bitmap != @default_bitmap }
    cache_tab.clear
  end
  # Test if a file exist
  # @param filename [String] filename of the image
  # @param path [String] path of the image inside Graphics/
  # @param file_data [Yuki::VD] "virtual directory"
  # @return [Boolean] if the image exist or not
  def test_file_existence(filename, path, file_data = nil)
    return true if file_data && file_data.exists?(filename.downcase)
    return true if File.exist?(format(Common_filename_format, path, filename).downcase)
    false
  end
  # Loads an image (from cache, disk or virtual directory)
  # @param cache_tab [Hash{String => Bitmap}] cache table where bitmaps are being stored
  # @param filename [String] filename of the image
  # @param path [String] path of the image inside Graphics/
  # @param file_data [Yuki::VD] "virtual directory"
  # @return [Bitmap]
  # @note This function displays a desktop notification if the image is not found. The resultat bitmap is an empty 16x16 bitmap in this case.
  def load_image(cache_tab, filename, path, file_data = nil)
    complete_filename = format(Common_filename, path, filename).downcase
    return bitmap = @default_bitmap if File.directory?(complete_filename)
    bitmap = cache_tab.fetch(filename, nil)
    if !bitmap || bitmap.disposed?
#      bitmap = load_image_from_file_data(filename, file_data) if file_data
#      bitmap = Bitmap.new(complete_filename) if !bitmap || bitmap.disposed?
      bitmap = Bitmap.new(complete_filename) if File.exist?(complete_filename + '.png')
      if (!bitmap or bitmap.disposed?) and file_data
        bitmap = load_image_from_file_data(filename, file_data)
      end
      bitmap = @default_bitmap unless bitmap
    end
  rescue Exception
    print "\r"
    puts Notification_title
    puts complete_filename
#    ::Yuki.send_notification(Notification_title, complete_filename) if filename && filename.size > 0
    bitmap = @default_bitmap
  ensure
    return cache_tab[filename] = bitmap
  end
  # Loads an image from virtual directory with the right encoding
  # @param filename [String] filename of the image
  # @param file_data [Yuki::VD] "virtual directory"
  # @return [Bitmap] the image loaded from the virtual directory
  def load_image_from_file_data(filename, file_data)
    bitmap_data = file_data.read_data(filename.downcase)
    if(bitmap_data)
      bitmap = Bitmap.new(bitmap_data, true)
=begin
      bitmap_data = ::Marshal.load(bitmap_data)
      if(bitmap_data.size == Sizeof_8bit_bitmap_data)
        bitmap = ::Bitmap.load_8bits(*bitmap_data)
      else
        bitmap = ::Bitmap.load_32bits(*bitmap_data)
      end
=end
    end
    bitmap
  end
  # Meta defintion of the cache loading without hue (shiny processing)
  Cache_meta_without_hue = <<-EOT
    LOADS << :load_%{cache_name}
    %{cache_constant}_Path = '%{cache_path}'
    module_function

    def load_%{cache_name}(flush_it = false)
      unless flush_it
        @%{cache_name}_cache = Hash.new
        @%{cache_name}_data = Yuki::VD.new(PSDK_PATH + "/master/%{cache_name}", :read)
      else
        dispose_bitmaps_from_cache_tab(@%{cache_name}_cache)
      end
    end

    def %{cache_name}_exist?(filename)
      test_file_existence(filename, %{cache_constant}_Path, @%{cache_name}_data)
    end

    def %{cache_name}(filename, _hue = 0)
      load_image(@%{cache_name}_cache, filename, %{cache_constant}_Path, @%{cache_name}_data)
    end

    def extract_%{cache_name}(path = '')
      path += %{cache_constant}_Path
      ori = Dir.pwd
      Dir.mkdir!(path.downcase)
      Dir.chdir(path.downcase)
      @%{cache_name}_data.get_filenames.each do |filename|
        if filename.include?('/')
          dirname = File.dirname(filename)
          Dir.mkdir!(dirname) unless Dir.exist?(dirname)
        end
        was_cached = @%{cache_name}_cache[filename] != nil
        bmp = %{cache_name}(filename)
        bmp.to_png_file(filename + '.png')
        bmp.dispose unless was_cached
      end
    ensure
      Dir.chdir(ori)
    end
  EOT
  # Meta definition of the cache loading with hue (shiny processing)
  Cache_meta_with_hue = <<-EOT
    LOADS << :load_%{cache_name}
    %{cache_constant}_Path = [%{cache_path}]
    module_function

    def load_%{cache_name}(flush_it = false)
      unless flush_it
        @%{cache_name}_cache = Array.new(%{cache_constant}_Path.size) { Hash.new }
        @%{cache_name}_data = [
          Yuki::VD.new(PSDK_PATH + "/master/%{cache_name}", :read),
          Yuki::VD.new(PSDK_PATH + "/master/%{cache_name}_s", :read)]
      else
        @%{cache_name}_cache.each { |cache_tab| dispose_bitmaps_from_cache_tab(cache_tab) }
      end
    end

    def %{cache_name}_exist?(filename, hue = 0)
      test_file_existence(filename, %{cache_constant}_Path.fetch(hue), @%{cache_name}_data[hue])
    end

    def %{cache_name}(filename, hue = 0)
      load_image(@%{cache_name}_cache.fetch(hue), filename, %{cache_constant}_Path.fetch(hue), @%{cache_name}_data[hue])
    end

    def extract_%{cache_name}(path = '', hue = 0)
      path += %{cache_constant}_Path[hue]
      ori = Dir.pwd
      Dir.mkdir!(path.downcase)
      Dir.chdir(path.downcase)
      @%{cache_name}_data[hue].get_filenames.each do |filename|
        if filename.include?('/')
          dirname = File.dirname(filename)
          Dir.mkdir!(dirname) unless Dir.exist?(dirname)
        end
        was_cached = @%{cache_name}_cache[hue][filename] != nil
        bmp = %{cache_name}(filename, hue)
        bmp.to_png_file(filename + '.png')
        bmp.dispose unless was_cached
      end
    ensure
      Dir.chdir(ori)
    end
  EOT
  # Execute a meta code generation (undef when done)
  def meta_exec(line, name, constant, path, meta_code = Cache_meta_without_hue)
    module_eval(
      format(
        meta_code, 
        cache_name: name,
        cache_constant: constant,
        cache_path: path,
      ),
      __FILE__,
      line
    )
  end
  # @!macro [attach] meta_exec
  #   Loads a bitmap from cache or Graphics/$4 directory
  #   @!method $2(filename, hue = 0)
  #   @param filename [String] name of the image in Graphics/$4
  #   @param hue [Integer] hue if the cache has hue (shiny processing)
  #   @return [Bitmap] the bitmap corresponding to the image
  meta_exec(__LINE__, 'animation', 'Animations', 'Animations')
  meta_exec(__LINE__, 'autotile', 'Autotiles', 'Autotiles')
  meta_exec(__LINE__, 'ball', 'Ball', 'Ball')
  meta_exec(__LINE__, 'battleback', 'BattleBacks', 'BattleBacks')
  meta_exec(__LINE__, 'battler', 'Battlers', 'Battlers')
  meta_exec(__LINE__, 'character', 'Characters', 'Characters')
  meta_exec(__LINE__, 'fog', 'Fogs', 'Fogs')
  meta_exec(__LINE__, 'icon', 'Icons', 'Icons')
  meta_exec(__LINE__, 'interface', 'Interface', 'Interface')
  meta_exec(__LINE__, 'panorama', 'Panoramas', 'Panoramas')
  meta_exec(__LINE__, 'particle', 'Particles', 'Particles')
  meta_exec(__LINE__, 'pc', 'PC', 'PC')
  meta_exec(__LINE__, 'picture', 'Pictures', 'Pictures')
  meta_exec(__LINE__, 'pokedex', 'Pokedex', 'Pokedex')
  meta_exec(__LINE__, 'title', 'Titles', 'Titles')
  meta_exec(__LINE__, 'tileset', 'Tilesets', 'Tilesets')
  meta_exec(__LINE__, 'transition', 'Transitions', 'Transitions')
  meta_exec(__LINE__, 'windowskin', 'Windowskins', 'Windowskins')
  meta_exec(__LINE__, 'foot_print', 'Pokedex_FootPrints', 'Pokedex/FootPrints')
  meta_exec(__LINE__, 'b_icon', 'Pokedex_PokeIcon', 'Pokedex/PokeIcon')

  meta_exec(
    __LINE__, 
    'poke_front', 
    'Pokedex_PokeFront', 
    %q('Pokedex/PokeFront', 'Pokedex/PokeFrontShiny'),
    Cache_meta_with_hue
  )
  meta_exec(
    __LINE__, 
    'poke_back', 
    'Pokedex_PokeBack', 
    %q('Pokedex/PokeBack', 'Pokedex/PokeBackShiny'),
    Cache_meta_with_hue
  )

  undef meta_exec
  remove_const :Cache_meta_without_hue
  remove_const :Cache_meta_with_hue
end
#> Tells what to do on Start
Graphics.on_start do
  puts 'Loading cache...'
  t = Time.new
  RPG::Cache::LOADS.each do |k|
    RPG::Cache.send(k)
  end
  puts format('Time to load cache : %<time>ss', time: (Time.new - t))
end
