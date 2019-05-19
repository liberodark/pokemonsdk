module Tools
  # Class that aim to merge the Pokemon sprites of a specific folder to less PNG files
  class MergePokemonSprite
    EXCLUSION = ['000.png']
    # Merge the Pokemon sprite of a specific folder into various PNG files
    # @param count [Integer] number of Sprite per sheet
    # @param width [Integer] width of a Sprite sheet
    # @param size [Integer] size of a single element of the sheet
    # @param icon_processing [Boolean] if the sheet contain icons (2 frame animation)
    # @param path [String] path to the folder containing the ressources
    # @param skip_existing [Boolean] skip existing merged file
    # @param delete_processed [Boolean] delete processed file
    def initialize(count, width, size, icon_processing, path, skip_existing, delete_processed)
      @count = count
      @width = width
      @size = size
      @icon_processing = icon_processing
      @skip_existing = skip_existing
      @delete_processed = delete_processed
      puts "Processing #{path}..."
      Dir.chdir(path) { process }
    end

    private

    # Process the image merge
    def process
      elements_to_process.each do |sheet_id, list|
        filename = format('%03d-%03d.png', sheet_id * @count + 1, (sheet_id + 1) * @count)
        if File.exist?(filename) && @skip_existing
          puts "Skipping #{filename}"
          next
        end
        puts "Processing #{filename}"
        image = Image.new(*image_size(list))
        paste_images(image, list)
        image.to_png_file(filename)
        image.dispose
      end
    end

    # Return the list of element to process in the current directory for each sheet
    # @return [Hash]
    def elements_to_process
      (Dir['*.png'].grep(/^[0-9]{3}.png/) - EXCLUSION).sort.group_by { |i| (i.to_i - 1) / @count }
    end

    # Return the best size for a image sheet
    # @param list [Array<String>] list of the files in the sheet
    # @return [Array(Integer, Integer)]
    def image_size(list)
      max = (list.max.to_i - 1) % @count
      number_of_element_per_line = @width / element_with

      # If there's only one line
      return [(max + 1) * element_with, @size] if max < number_of_element_per_line

      # If there's more than one line, we count the number of required lines
      number_of_line = max / number_of_element_per_line + 1
      return [@width, @size * number_of_line]
    end

    # Paste all the image of the list in the given image
    # @param image [LiteRGSS::Image]
    # @param list [Array<String>]
    def paste_images(image, list)
      el_width = element_with
      max_element_per_line = @width / el_width
      list.each do |element|
        index = (element.to_i - 1) % @count
        source_image = LiteRGSS::Image.new(element)
        x = (index % max_element_per_line) * el_width
        y = (index / max_element_per_line) * @size
        if @icon_processing && source_image.width != el_width
          image.blt!(x, y, source_image, source_image.rect)
          rect = source_image.rect
          rect.y = 1
          rect.height -= 1
          image.blt(x + @size, y, source_image, rect)
          auto_delete(element, source_image)
          source_image.dispose
          next
        end
        image.blt!(x, y, source_image, source_image.rect)
        auto_delete(element, source_image)
        source_image.dispose
      end
    end

    # Automatically delete a PNG file
    # @param element [String] name of the element
    # @param image [LiteRGSS::Image] source image
    def auto_delete(element, image)
      return unless @delete_processed

      File.delete(element) if image.width <= element_with && image.height <= @size
    end

    # Return the element width
    # @return [Integer]
    def element_with
      @size * (@icon_processing ? 2 : 1)
    end

    class << self
      # Merge all the Pokemon Sprite
      # @param skip_existing [Boolean] skip existing merged file
      # @param delete_processed [Boolean] delete processed file
      def merge_all(skip_existing = true, delete_processed = false)
        sz = PFM::Pokemon::BATTLER_SIZE
        pk_count = (1024 / sz)**2
        pk_width = (1024 / sz) * sz
        MergePokemonSprite.new(pk_count, pk_width, sz, false, 'graphics/pokedex/pokefront', skip_existing, delete_processed)
        MergePokemonSprite.new(pk_count, pk_width, sz, false, 'graphics/pokedex/pokefrontshiny', skip_existing, delete_processed)
        MergePokemonSprite.new(pk_count, pk_width, sz, false, 'graphics/pokedex/pokeback', skip_existing, delete_processed)
        MergePokemonSprite.new(pk_count, pk_width, sz, false, 'graphics/pokedex/pokebackshiny', skip_existing, delete_processed)
        sz = PFM::Pokemon::FOOT_SIZE
        fp_count = (1024 / sz)**2
        fp_width = (1024 / sz) * sz
        MergePokemonSprite.new(fp_count, fp_width, sz, false, 'graphics/pokedex/footprints', skip_existing, delete_processed)
        sz = PFM::Pokemon::ICON_SIZE
        ic_count = (512 / sz) * (1024 / sz)
        ic_width = (1024 / sz) * sz
        MergePokemonSprite.new(ic_count, ic_width, sz, true, 'graphics/pokedex/pokeicon', skip_existing, delete_processed)
      end
    end
  end
end
