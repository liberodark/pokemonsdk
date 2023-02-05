module PFM
  class Pokemon
    # All possible attempt of finding an egg (for legacy)
    # @todo Change this later
    EGG_FILENAMES = ['egg_%<id>03d_%<form>02d', 'egg_%<id>03d', 'egg_%<name>s_%<form>02d', 'egg_%<name>s', 'egg']
    # Size of a battler
    BATTLER_SIZE = 96
    # Size of an icon
    ICON_SIZE = 32
    # Size of a footprint
    FOOT_SIZE = 16

    # Return the ball image of the Pokemon
    # @return [Texture]
    def ball_image
      return RPG::Cache.ball(ball_sprite)
    end

    class << self
      # Icon filename of a Pokemon
      # @param id [Integer] ID of the Pokemon
      # @param form [Integer] form index of the Pokemon
      # @param female [Boolean] if the Pokemon is a female
      # @param shiny [Boolean] shiny state of the Pokemon
      # @param egg [Boolean] egg state of the Pokemon
      # @return [String]
      def icon_filename(id, form, female, shiny, egg)
        format_arg = { id: id, form: form, name: data_creature(id).db_symbol }
        cache_exist = RPG::Cache.method(:b_icon_exist?)
        return correct_filename_from(EGG_FILENAMES, format_arg, cache_exist) || EGG_FILENAMES.last if egg

        resources = data_creature_form(id, form).resources
        filename = resources.icon_shiny_f if resources.has_female && shiny && female
        filename ||= resources.icon_f if resources.has_female && female
        filename ||= resources.icon_shiny if shiny
        filename = filename && !filename&.empty? && RPG::Cache.b_icon_exist?(filename) ? filename : resources.icon
        return filename || '000'
      end

      # Return the front battler name
      # @param id [Integer] ID of the Pokemon
      # @param form [Integer] form index of the Pokemon
      # @param female [Boolean] if the Pokemon is a female
      # @param shiny [Boolean] shiny state of the Pokemon
      # @param egg [Boolean] egg state of the Pokemon
      # @return [String]
      def front_filename(id, form, female, shiny, egg)
        format_arg = { id: id, form: form, name: data_creature(id).db_symbol }
        return correct_filename_from(EGG_FILENAMES, format_arg, RPG::Cache.method(:poke_front_exist?)) || EGG_FILENAMES.last if egg

        resources = data_creature_form(id, form).resources
        filename = resources.front_shiny_f if resources.has_female && shiny && female
        filename ||= resources.front_f if resources.has_female && female
        filename ||= resources.front_shiny if shiny
        return filename || resources.front || '000'
      end

      # Return the front gif name
      # @param id [Integer] ID of the Pokemon
      # @param form [Integer] form index of the Pokemon
      # @param female [Boolean] if the Pokemon is a female
      # @param shiny [Boolean] shiny state of the Pokemon
      # @param egg [Boolean] egg state of the Pokemon
      # @return [String, nil]
      def front_gif_filename(id, form, female, shiny, egg)
        hue = shiny ? 1 : 0
        cache_exist = proc { |filename| RPG::Cache.poke_front_exist?(filename, hue) }
        filename = front_filename(id, form, female, shiny, egg) + '.gif'
        return filename = filename_exist(filename, cache_exist)
      end

      # Return the back battler name
      # @param id [Integer] ID of the Pokemon
      # @param form [Integer] form index of the Pokemon
      # @param female [Boolean] if the Pokemon is a female
      # @param shiny [Boolean] shiny state of the Pokemon
      # @param egg [Boolean] egg state of the Pokemon
      # @return [String]
      def back_filename(id, form, female, shiny, egg)
        format_arg = { id: id, form: form, name: data_creature(id).db_symbol }
        return correct_filename_from(EGG_FILENAMES, format_arg, RPG::Cache.method(:poke_back_exist?)) || EGG_FILENAMES.last if egg

        resources = data_creature_form(id, form).resources
        filename = resources.back_shiny_f if resources.has_female && shiny && female
        filename ||= resources.back_f if resources.has_female && female
        filename ||= resources.back_shiny if shiny
        return filename || resources.back || '000'
      end

      # Return the back gif name
      # @param id [Integer] ID of the Pokemon
      # @param form [Integer] form index of the Pokemon
      # @param female [Boolean] if the Pokemon is a female
      # @param shiny [Boolean] shiny state of the Pokemon
      # @param egg [Boolean] egg state of the Pokemon
      # @return [String, nil]
      def back_gif_filename(id, form, female, shiny, egg)
        hue = shiny ? 1 : 0
        cache_exist = proc { |filename| RPG::Cache.poke_back_exist?(filename, hue) }
        filename = back_filename(id, form, female, shiny, egg) + '.gif'
        return filename = filename_exist(filename, cache_exist)
      end

      private

      # Find the correct filename in a collection (for legacy egg sprites checks)
      # @param formats [Array<String>]
      # @param format_arg [Hash]
      # @param cache_exist [Method, Proc]
      # @return [String, nil] formated filename if it exists
      def correct_filename_from(formats, format_arg, cache_exist)
        formats.each do |filename_format|
          filename = format(filename_format, format_arg)
          return filename if cache_exist.call(filename)
        end

        return nil
      end

      # Check if the filename exists in the cache
      # @param filename [String]
      # @param cache_exist [Method, Proc]
      # @return [String, nil] filename if it exists
      def filename_exist(filename, cache_exist)
        return filename if cache_exist.call(filename)

        return nil
      end
    end

    # Return the icon of the Pokemon
    # @return [Texture]
    def icon
      return RPG::Cache.b_icon(PFM::Pokemon.icon_filename(id, form, female?, shiny?, egg?))
    end

    # Return the front battler of the Pokemon
    # @return [Texture]
    def battler_face
      return RPG::Cache.poke_front(PFM::Pokemon.front_filename(id, form, female?, shiny?, egg?), shiny? ? 1 : 0)
    end
    alias battler_front battler_face

    # Return the back battle of the Pokemon
    # @return [Texture]
    def battler_back
      return RPG::Cache.poke_back(PFM::Pokemon.back_filename(id, form, female?, shiny?, egg?), shiny? ? 1 : 0)
    end

    # Return the front offset y of the Pokemon
    # @return [Integer]
    def front_offset_y
      return data.front_offset_y
    end

    # Return the character name of the Pokemon
    # @return [String]
    def character_name
      unless @character
        resources = data_creature_form(id, form).resources
        filename = resources.character_shiny_f if shiny && female?
        filename ||= resources.character_f if female?
        filename ||= resources.character_shiny if shiny?
        @character = filename || resources.character || '000'
      end
      return @character
    end

    # Return the cry file name of the Pokemon
    # @return [String]
    def cry
      return nil.to_s if @step_remaining > 0

      cry = data&.resources&.cry
      return "Audio/SE/Cries/#{data.resources.cry}" if cry && !cry&.empty? && File.exist?("Audio/SE/Cries/#{cry}")

      return format('Audio/SE/Cries/%03dCry', @id)
    end

    # Return the GifReader face of the Pokemon
    # @return [::Yuki::GifReader, nil]
    def gif_face
      return nil unless @step_remaining

      filename = Pokemon.front_gif_filename(@id, @form, female?, shiny?, false)
      return filename && Yuki::GifReader.new(RPG::Cache.poke_front(filename, shiny? ? 1 : 0), true)
    end

    # Return the GifReader back of the Pokemon
    # @return [::Yuki::GifReader, nil]
    def gif_back
      return nil unless @step_remaining

      filename = Pokemon.back_gif_filename(@id, @form, female?, shiny?, false)
      return filename && Yuki::GifReader.new(RPG::Cache.poke_back(filename, shiny? ? 1 : 0), true)
    end
  end
end
