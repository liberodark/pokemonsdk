# Module responsive of giving access to various configuration contained into Data/configs
#
# @example How to create a basic configuration
#   module Configs
#     class MyConfigDescription
#       # Define attributes etc...
#       def initialize # <= Configs will call this without argument so you can set default value if file does not exist
#       end
#     end
#     # @!method self.my_config_accessor
#     #   @return [MyConfigDescription]
#     register(:my_config_accessor, 'my_config', :json, false, MyConfigDescription)
#   end
module Configs
  # List of all registered configs
  @all_registered_configs = {}
  # List of keys from file to ruby world
  KEY_TRANSLATIONS = {
    isMouseDisabled: :is_mouse_disabled,
    mouseSkin: :mouse_skin,
    gameResolution: :game_resolution,
    windowScale: :window_scale,
    isFullscreen: :is_fullscreen,
    isPlayerAlwaysCentered: :is_player_always_centered,
    tilemapSettings: :tilemap_settings,
    introMovieMapId: :intro_movie_map_id,
    bgmName: :bgm_name,
    bgmDuration: :bgm_duration,
    isLanguageSelectionEnabled: :language_selection_enabled,
    additionalSplashes: :additional_splashes,
    controlWaitTime: :control_wait,
    maximumSave: :maximum_save_count,
    saveKey: :save_key,
    saveHeader: :save_header,
    baseFilename: :base_filename,
    isCanSaveOnAnySave: :can_save_on_any_save,
    projectSplash: :project_splash,
    lineHeight: :line_height,
    scrollSpeed: :speed,
    leaderSpacing: :leader_spacing,
    chiefProjectTitle: :chief_project_title,
    chiefProjectName: :chief_project_name,
    gameCredits: :game_credits,
    pokemonMaxLevel: :max_level,
    isAlwaysUseForm0ForEvolution: :always_use_form0_for_evolution,
    isUseForm0WhenNoEvolutionData: :use_form0_when_no_evolution_data,
    maxBagItemCount: :max_bag_item_count,
    isSmoothTexture: :smooth_texture,
    isVsyncEnabled: :vsync_enabled,
    gameTitle: :game_title,
    gameVersion: :game_version,
    defaultLanguage: :default_language_code,
    choosableLanguageCode: :choosable_language_code,
    choosableLanguageTexts: :choosable_language_texts
  }
  # Name of the file that must exist if we want to successfully load scripts
  SCRIPTS_REQUIRED_CONFIG = 'Data/configs/display_config.json'

  class << self
    # Register a new config
    # @param name [Symbol] name of the config
    # @param filename [String] name of the file inside Data/configs
    # @param type [Symbol] type of the config file: :yml or :json
    # @param preload [Boolean] if the file need to be preloaded
    # @param klass [Class] class describing the config content
    def register(name, filename, type, preload, klass)
      @all_registered_configs[name] = { filename: filename, type: type, klass: klass }
      if preload
        load_file_data(name)
      else
        define_singleton_method(name) { load_file_data(name) }
      end
    end

    private

    # Function that loads the file data
    # @param name [Symbol] name of the file data to load
    # @return [Object, nil] whatever was loaded or initialized
    def load_file_data(name)
      return unless (info = @all_registered_configs[name])

      rxdata_filename = format('Data/configs/%<filename>s.rxdata', filename: clean_filename(info[:filename]))
      if PSDK_CONFIG.release?
        data = load_data(rxdata_filename)
        define_singleton_method(name) { data }
        return data
      end

      real_filename = format('Data/configs/%<filename>s.%<ext>s', filename: info[:filename], ext: info[:type])
      dirname = File.dirname(real_filename)
      Dir.mkdir!(dirname) unless Dir.exist?(dirname)
      data = load_config_data(info, rxdata_filename, real_filename)

      define_singleton_method(name) { data }
      return data
    end

    # Function that cleans the filename for rxdata files
    # @param filename [String]
    # @return [String]
    def clean_filename(filename)
      filename.gsub('/', '_')
    end

    # Function that load the config data in non-release mode
    # @param info [Hash]
    # @param rxdata_filename [String]
    # @param real_filename [String]
    def load_config_data(info, rxdata_filename, real_filename)
      if File.exist?(real_filename) && File.exist?(rxdata_filename) && (File.mtime(real_filename) <= File.mtime(rxdata_filename))
        return load_data(rxdata_filename)
      elsif File.exist?(real_filename)
        log_info("Loading config file #{real_filename}")
        file_content = File.read(real_filename)
        data = info[:type] == :yml ? YAML.unsafe_load(file_content) : JSON.parse(file_content, symbolize_names: true)
        if data.is_a?(Hash)
          pre_data = data
          data = info[:klass].new
          pre_data.each do |key, value|
            next if key == :klass

            data.send("#{KEY_TRANSLATIONS[key] || key}=", value)
          end
        elsif !data.is_a?(info[:klass])
          raise "Invalid klass #{data.class} for file #{real_filename}, expected #{info[:klass]}"
        end
      elsif real_filename == SCRIPTS_REQUIRED_CONFIG
        ScriptLoader.load_tool('PSDKEditor')
        PSDK_CONFIG.send(:initialize)
        PSDKEditor.convert_display_settings
        PSDKEditor.convert_texts_settings
        PSDKEditor.convert_infos_settings
        return load_config_data(info, rxdata_filename, real_filename)
      else
        log_info("Creating config file #{real_filename}")
        data = File.exist?(rxdata_filename) ? load_data(rxdata_filename) : info[:klass].new
        File.write(real_filename, info[:type] == :yml ? YAML.dump(data) : JSON.dump(data))
      end

      save_data(data, rxdata_filename)
      return data
    end
  end
end
