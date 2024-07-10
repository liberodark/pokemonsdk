# Module holding all the Studio data definition
module Studio
  # Module that helps the game to get text in various langages
  # @author Nuri Yuri
  module Text
    # List of lang id available in the game
    Available_Langs = %w[en fr it de es ko kana]
    # Base index of pokemon text in csv files
    CSV_BASE = 100_000
    # Name of the file containing all the dialogs
    VD_TEXT_FILENAME = 'Data/2.dat'
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
      reload_rh_texts unless PSDK_CONFIG.release?
      lang = (PFM.game_state ? PFM.game_state.options.language : default_lang)
      unless lang && Available_Langs.include?(lang)
        log_error "Unsupported language code (#{lang}).\nSupported language code are : #{Available_Langs.join(', ')}"
        lang = Available_Langs.first
        log_info "Fallback language code : #{lang}"
      end
      @lang = lang
      @dialogs.clear
    end

    # Return the default game lang
    # @return [String]
    def default_lang
      Configs.language.default_language_code
    end

    # Get a text front the text database
    # @param file_id [Integer] ID of the text file
    # @param text_id [Integer] ID of the text in the file
    # @return [String] the text
    def get(file_id, text_id)
      return get_dialog_message(CSV_BASE + file_id, text_id) if file_id < 100_000

      return get_dialog_message(file_id, text_id)
    end

    # Get a list of text from the text database
    # @param file_id [Integer] ID of the text file
    # @return [Array<String>] the list of text contained in the file.
    def get_file(file_id)
      file_id += CSV_BASE
      return @dialogs[file_id] if @dialogs.key?(file_id)
      unless try2get_marshalized_dialog(file_id) || try2get_csv_dialog(file_id)
        return log_error("Text file #{file_id - CSV_BASE} doesn't exist.")
      end
      return @dialogs[file_id]
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
    module_function :get_external

    # Try to load a preprocessed dialog file (Marshal)
    # @param file_id [Integer] id of the dialog file
    # @return [Boolean] if the operation was a success
    def try2get_marshalized_dialog(file_id)
      filename = format('Data/Text/Dialogs/%<id>d.%<lang>s.dat', id: file_id, lang: @lang)
      if marshalized_text_file_exist?(filename)
        @dialogs[file_id] = load_data(filename)
        log_info("Marshal text #{filename} was loaded") if debug?
        return true
      end
      return false
    end

    # Test if a marshalized text file exist
    # @param filename [String] name of the file in Data/text/Dialogs
    # @return [Boolean]
    def marshalized_text_file_exist?(filename)
      if PSDK_CONFIG.release?
        vdfilename = VD_TEXT_FILENAME
        ::Kernel::Loaded[vdfilename] = Yuki::VD.new(vdfilename, :read) unless ::Kernel::Loaded.key?(vdfilename)
        return ::Kernel::Loaded[vdfilename].exists?(File.basename(filename))
      end
      return File.exist?(filename)
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
        log_info("CSV text #{filename} was loaded") if debug?
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

    # Marshalize the dialogs
    def compile
      Dir.chdir('Data/Text/Dialogs') do
        Dir['*.csv'].grep(/^[0-9]+\.csv$/).each { |filename| compile_csv(filename) }
      end
    end

    # Compile a single csv file
    # @param filename [String] name of the csv file
    def compile_csv(filename)
      file_id = filename.to_i
      rows = CSV.read(filename)
      rows.first.each_with_index do |lang, lang_index|
        next unless Available_Langs.include?(lang = lang.strip.downcase)
        arr = build_dialog_from_csv_rows(rows, lang_index)
        output_filename = format('%<id>d.%<lang>s.dat', id: file_id, lang: lang)
        save_data(arr, output_filename)
      end
    end

    # Reload texts from Ruby Host
    def reload_rh_texts
      langs = Dir["Data/Text/Dialogs/#{CSV_BASE}.*.dat"].collect { |i| i.match(/[0-9]+\.([a-z]+)\.dat$/).captures[0] }
      if langs.empty? || (!File.exist?('project.studio') &&
        File.mtime("Data/Text/Dialogs/#{CSV_BASE}.#{langs.first}.dat") < File.mtime("Data/Text/#{langs.first}.dat"))
        langs.concat(Configs.language.choosable_language_code) if langs.empty? # Must add all project supported languages
        langs << Configs.language.default_language_code if langs.empty?
        unless File.exist?('project.studio') # No RH back compilation for studio project!
          log_debug('Updating Text files')
          ScriptLoader.load_tool('Text2CSV')
        end
        Available_Langs.clear
        Available_Langs.concat(langs)
        log_debug('Compiling Text files')
        compile
      else
        denom = "#{langs.first}.dat"
        must_update = Dir["Data/Text/Dialogs/*.#{denom}"].any? do |dat_filename|
          csv_filename = dat_filename.sub(denom, 'csv')
          next false unless File.exist?(csv_filename)

          next File.mtime(dat_filename) < File.mtime(csv_filename)
        end
        if must_update
          log_debug('Recompiling texts from CSV')
          compile
        end
      end
    end
  end
end
