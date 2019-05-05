require 'csv'

module GameData
  # Module that helps the game to get text in various langages
  # @author Nuri Yuri
  module Text
    # List of lang id available in the game
    Available_Langs = %w[en fr it de es ko kana].freeze
    # List of texts in the current language
    # @type [Array<Array<String>>]
    @texts = []
    # List of cached dialogs
    # @type [Hash{Integer => Array<String>}]
    @dialogs = {}
    # Current language
    # @type [String]
    @lang = nil

    module_function

    # load text in the correct lang ($options.language or LANG in game.ini)
    def load
      lang = ($pokemon_party ? $pokemon_party.options.language : default_lang)
      unless lang && Available_Langs.include?(lang)
        log_error "Unsupported language code (#{lang}).\nSupported language code are : #{Available_Langs.join(', ')}"
        lang = Available_Langs.first
        log_info "Fallback language code : #{lang}"
      end
      @texts = Marshal.load(Zlib::Inflate.inflate(load_data("Data/Text/#{lang}.dat")))
      @lang = lang
      @dialogs.clear
    end

    # Return the default game lang
    # @return [String]
    def default_lang
      GamePlay::Load::DEFAULT_GAME_LANGUAGE
    end

    # Get a text front the text database
    # @param file_id [Integer] ID of the text file
    # @param text_id [Integer] ID of the text in the file
    # @return [String] the text
    def get(file_id, text_id)
      if (file = @texts[file_id])
        if (text = file[text_id])
          return text
        end
        return log_error("Unable to find text #{text_id} in file #{file_id}.")
      end
      return log_error("Text file #{file_id} doesn't exist.")
    end

    # Get a list of text from the text database
    # @param file_id [Integer] ID of the text file
    # @return [Array<String>] the list of text contained in the file.
    def get_file(file_id)
      if (file = @texts[file_id])
        return file
      end
      return log_error("File #{file_id} doesn't exist.")
    end

    # Get a dialog message
    # @param file_id [Integer] id of the dialog file
    # @param text_id [Integer] id of the dialog message in the file (0 = 2nd line of csv, 1 = 3rd line of csv)
    # @return [String] the text
    def get_dialog_message(file_id, text_id)
      # Try to find the text from the cache
      if (file = @dialogs[file_id])
        if (text = file[text_id])
          return text
        end
        return log_error("Unable to find text #{text_id} in dialog file #{file_id}.")
      end
      # Try to load the texts
      unless try2get_marshalized_dialog(file_id) || try2get_csv_dialog(file_id)
        return log_error("Dialog file #{file_id} doesn't exist.")
      end
      # Return the result after the text was loaded
      return get_dialog_message(file_id, text_id)
    end
    alias get_external get_dialog_message
    module_function(:get_external)

    # Try to load a preprocessed dialog file (Marshal)
    # @param file_id [Integer] id of the dialog file
    # @return [Boolean] if the operation was a success
    def try2get_marshalized_dialog(file_id)
      if File.exist?(filename = format('Data/Text/Dialogs/%d.%s.dat', file_id, @lang))
        @dialogs[file_id] = load_data(filename)
        return true
      end
      return false
    end

    # Try to load a csv dialog file
    # @param file_id [Integer] id of the dialog file
    # @return [Boolean] if the operation was a success
    def try2get_csv_dialog(file_id)
      if File.exist?(filename = format('Data/Text/Dialogs/%<file_id>d.csv', file_id: file_id))
        rows = CSV.read(filename)
        lang_index = rows.first.index { |el| el.strip.downcase == @lang }
        unless lang_index
          lang_index = rows.first.index { |el| Available_Langs.include?(el.strip.downcase) }
          unless lang_index
            log_error("Failed to find any lang in #{filename}")
            @dialogs[file_id] = []
            return true
          end
        end
        @dialogs[file_id] = build_dialog_from_csv_rows(rows, lang_index)
        return true
      end
      return false
    end

    # Build the text array from the csv rows
    # @param rows [Array]
    # @param lang_index [Integer]
    # @return [Array<String>]
    def build_dialog_from_csv_rows(rows, lang_index)
      return Array.new(rows.size - 1) do |i|
        rows[i + 1][lang_index].to_s.gsub('\nl', "\n")
      end
    end
  end
end
