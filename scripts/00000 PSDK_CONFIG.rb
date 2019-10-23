# Class describing the PSDK Config
module ScriptLoader
  class PSDKConfig
    # @return [String] the game title
    attr_reader :game_title
    # @return [Integer] game version
    attr_reader :game_version
    # @return [String] the game resolution
    attr_reader :native_resolution
    # @return [String] default language of the game
    attr_reader :default_language_code
    # @return [Array<String>] list of language the player can choose
    attr_reader :choosable_language_code
    # @return [Array<String>] list of language the player can choose (names)
    attr_reader :choosable_language_texts
    # @return [Integer] number of saves the player can have
    attr_reader :maximum_saves
    # @return [Integer] the window scale
    attr_reader :window_scale
    # @return [Boolean] if the game runs in fullscreen
    attr_reader :running_in_full_screen
    # @return [Boolean] if textures are smooth
    attr_reader :smooth_texture
    # @return [Boolean] if the game runs in VSYNC
    attr_reader :vsync_enabled
    # @return [Integer] the pokemon max level
    attr_reader :pokemon_max_level
    # @return [Boolean] if the player is always centered
    attr_reader :player_always_centered
    # @return [Boolean] if the mouse is disabled
    attr_reader :mouse_disabled
    # @return [Integer, nil] Specific zoom for overworld things
    attr_reader :specific_zoom
    # @return [Integer] OffsetX of all the viewports
    attr_reader :viewport_offset_x
    # @return [Integer] OffsetY of all the viewports
    attr_reader :viewport_offset_y
    # @return [TilemapConfig] tilemap configurations
    attr_reader :tilemap
    # Name of the yaml file
    YAML_FILENAME = 'Data/project_indentity.yml'
    # Name of the dat file
    DAT_FILENAME = 'Data/project_identity.rxdata'
    # List of legal aspect ratio
    ALLOWED_RATIOS = [4 / 3r, 16 / 9r, 16 / 10r]
    # Create the PSDK Config
    def initialize
      data = try_to_load_config
      data&.instance_variables&.each do |ivar_name|
        instance_variable_set(ivar_name, data.instance_variable_get(ivar_name))
      end
      fix_variables(!data || ($DEBUG && !File.exist?(DAT_FILENAME)))
      adjust_litergss_config
    end

    private

    # Try to load configs from data or yml
    # @return [PSDKConfig]
    def try_to_load_config
      data = load_data(DAT_FILENAME) rescue nil
      unless data
        if File.exist?(YAML_FILENAME)
          require 'yaml'
          data = YAML.load(File.read(YAML_FILENAME))
        end
      end
      return data.is_a?(PSDKConfig) ? data : nil
    end

    # Function that fix the variables
    # @param save [Boolean] if the object should be saved
    def fix_variables(save)
      @game_title = (@game_title || Config::Title).to_s
      @game_version = (@game_version || 256).to_i
      @default_language_code = (@default_language_code || 'en').to_s
      @choosable_language_code ||= %w[en fr es]
      @choosable_language_texts ||= %w[English French Spanish]
      @maximum_saves = (@maximum_saves || 4).to_i
      fix_resolution
      fix_scale
      fix_full_screen
      fix_smooth_texture
      fix_vsync
      @pokemon_max_level = (@pokemon_max_level || 100).to_i
      @player_always_centered = @player_always_centered == true
      @mouse_disabled = @mouse_disabled == true
      @tilemap = @tilemap.is_a?(TilemapConfig) ? @tilemap : TilemapConfig.new
      save |= @tilemap.fix_missing_values
      if save
        require 'yaml'
        File.write(YAML_FILENAME, YAML.dump(self))
        save_data(self, DAT_FILENAME)
      end
    end

    # Function that fix the native resolution
    def fix_resolution
      resolution = (@native_resolution || "#{Config::ScreenWidth}x#{Config::ScreenHeight}")
                   .to_s.split('x').collect(&:to_i)[0, 2]
      resolution = [320, 240] unless resolution.size == 2
      ratio = resolution.first.to_r / resolution.last
      unless ALLOWED_RATIOS.include?(ratio)
        puts format('Invalid screen aspect ratio %<top>d:%<bottom>d.', top: ratio.numerator, bottom: ratio.denominator)
      end
      @native_resolution = resolution.join('x')
    end

    # Function that fix the scale
    def fix_scale
      @window_scale = (PARGV[:scale] || @window_scale).to_i
      @window_scale = 2 if @window_scale < 0.1
    end

    # Function that fix the fullscreen
    def fix_full_screen
      param = PARGV[:fullscreen]
      @running_in_full_screen = (param.nil? ? @running_in_full_screen : param) == true
    end

    # Function that fix the smooth_texture
    def fix_smooth_texture
      param = PARGV[:smooth]
      @smooth_texture = (param.nil? ? @smooth_texture : param) == true
    end

    # Function that fix the vsync param
    def fix_vsync
      param = PARGV[:"no-vsync"]
      @vsync_enabled = (param.nil? ? @vsync_enabled : !param) == true
    end

    # Function that adjust the liteRGSS configs
    def adjust_litergss_config
      resolution = choose_best_resolution
      param = self
      Config.module_eval do
        remove_const :Title if const_defined?(:Title)
        const_set :Title, param.game_title
        remove_const :ScreenWidth if const_defined?(:ScreenWidth)
        const_set :ScreenWidth, resolution.first
        remove_const :ScreenHeight if const_defined?(:ScreenHeight)
        const_set :ScreenHeight, resolution.last
        remove_const :ScreenScale if const_defined?(:ScreenScale)
        const_set :ScreenScale, param.window_scale
        remove_const :SmoothScreen if const_defined?(:SmoothScreen)
        const_set :SmoothScreen, param.smooth_texture
        remove_const :FullScreen if const_defined?(:FullScreen)
        const_set :FullScreen, param.running_in_full_screen
        remove_const :Vsync if const_defined?(:Vsync)
        const_set :Vsync, param.vsync_enabled
      end
    end

    # Function that choose the best resolution
    # @return [Array<Integer>]
    def choose_best_resolution
      return editors_resolution if running_editor?
      native = @native_resolution.split('x').collect(&:to_i)
      @viewport_offset_x = 0
      @viewport_offset_y = 0
      if @running_in_full_screen
        desired = [native.first * @window_scale, native.last * @window_scale].map(&:round)
        all_res = Graphics.list_resolutions
        return native if all_res.include?(desired)
        if all_res.include?(native)
          @window_scale = 1
          return native
        end
        return find_best_matching_resolution(native, desired, all_res)
      else
        return native
      end
    end

    # Return the editor resolution
    # @return [Array<Integer>]
    def editors_resolution
      @window_scale = 1
      @running_in_full_screen = false
      return [640, 480]
    end

    # Tell if the game is running an editor
    def running_editor?
      return PARGV[:tags] || PARGV[:worldmap]
    end

    # Function that tries to find the best resolution in all_res according to native & desired
    # @param native [Array<Integer>] native screen resolution
    # @param desired [Array<Integer>] desired screen resolution
    # @param all_res [Array<Array>] all the compatible resolution
    # @return [Array<Integer>]
    def find_best_matching_resolution(native, desired, all_res)
      all_res = all_res.sort # Make sure we can find the first that matches
      unless (desired_res = all_res.find { |res| res.first >= desired.first && res.last >= desired.last })
        @window_scale = 1
        unless (desired_res = all_res.find { |res| res.first >= native.first && res.last >= native.last })
          desired_res = all_res.last
        end
      end
      @viewport_offset_x = ((desired_res.first / @window_scale - native.first) / 2).round
      @viewport_offset_y = ((desired_res.last / @window_scale - native.last) / 2).round
      return [desired_res.first / @window_scale, desired_res.last / @window_scale].map(&:round)
    end

    # Class describing the tilemap configuation
    class TilemapConfig
      # @return [String] full constant path of the tilemap class (from Object)
      attr_reader :tilemap_class
      # @return [Integer] number of tile in x to properly show the tilemap
      attr_reader :tilemap_size_x
      # @return [Integer] number of tiles in y to properly show the tilemap
      attr_reader :tilemap_size_y
      # @return [Integer] number of frame an autotile wait before being refreshed
      attr_reader :autotile_idle_frame_count
      # @return [Float] zoom of tiles in sprite character
      attr_reader :character_tile_zoom
      # @return [Integer] player center x value
      attr_reader :center_x
      # @return [Intger] player center y value
      attr_reader :center_y
      # @return [Integer] number of tile in x to make a proper map transition with map linker
      attr_reader :maplinker_offset_x
      # @return [Integer] number of tile in y to make a proper map transition with map linker
      attr_reader :maplinker_offset_y

      # Create a new TilemapConfig
      def initialize
        @tilemap_class = 'Tilemap::WithLessRubySprites_16'
        @tilemap_size_x = 22
        @tilemap_size_y = 17
        @character_tile_zoom = 0.5
        @center_x = (320 - 16) * 4
        @center_y = (240 - 16) * 4
        @maplinker_offset_x = 10
        @maplinker_offset_y = 7
        @autotile_idle_frame_count = 6
      end

      # Function that fix the missing values
      # @return [Boolean] if the files should be saved again
      def fix_missing_values
        return $DEBUG && false
      end
    end
  end
end
# Constant containing all the PSDK Config
PSDK_CONFIG = ScriptLoader::PSDKConfig.new
