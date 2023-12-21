# Class describing the PSDK Config
module ScriptLoader
  # PSDK config info so the game knows what's the context at start
  class PSDKConfig
    # @return [Integer] the window scale
    attr_reader :window_scale
    # @return [Boolean] if the game runs in fullscreen
    attr_reader :running_in_full_screen
    # @return [Boolean] if the game runs in VSYNC
    attr_reader :vsync_enabled
    # @return [Integer] OffsetX of all the viewports
    attr_reader :viewport_offset_x
    # @return [Integer] OffsetY of all the viewports
    attr_reader :viewport_offset_y

    # Tell if the game is in Release mode
    # @return [Boolean]
    def release?
      @release = File.exist?('Data/Scripts.dat') if @release.nil?
      return @release
    end

    # Tell if the game is in Debug mode
    # @return [Boolean]
    def debug?
      @debug = !release? && ARGV.include?('debug') if @debug.nil?
      return @debug
    end

    # Function that choose the best resolution
    # @return [Array<Integer>]
    def choose_best_resolution
      @window_scale = Configs.display.window_scale
      @vsync_enabled = Configs.graphic.vsync_enabled
      @running_in_full_screen = Configs.display.is_fullscreen
      fix_scale
      fix_vsync
      fix_full_screen
      return editors_resolution if running_editor?

      native = [Configs.display.game_resolution.x, Configs.display.game_resolution.y]
      @viewport_offset_x = 0
      @viewport_offset_y = 0
      if @running_in_full_screen
        desired = [native.first * @window_scale, native.last * @window_scale].map(&:round)
        all_res = LiteRGSS::DisplayWindow.list_resolutions
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

    private

    # Function that fix the scale
    def fix_scale
      @window_scale = (PARGV[:scale] || @window_scale).to_i
      @window_scale = 2 if @window_scale < 0.1
      if PARGV[:scale] && ARGV.include?(new_opt = "--scale=#{PARGV[:scale].to_i}")
        PARGV.update_game_opts(new_opt)
      end
    end

    # Function that fix the fullscreen
    def fix_full_screen
      param = PARGV[:fullscreen] || PSDK_PLATFORM == :android
      @running_in_full_screen = (param.nil? ? @running_in_full_screen : param) == true
    end

    # Function that fix the vsync param
    def fix_vsync
      @vsync_enabled = !PARGV[:"no-vsync"]
    end

    # Return the editor resolution
    # @return [Array<Integer>]
    def editors_resolution
      @window_scale = 1
      @running_in_full_screen = false
      @viewport_offset_x = 0
      @viewport_offset_y = 0
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
      # Exclude "inversed" resolutions (inversed aspect ratio), eg 1080x1920 != 1920x1080
      # Make sure we can find the first that matches
      current_ratio = LiteRGSS::DisplayWindow.desktop_width / LiteRGSS::DisplayWindow.desktop_height >= 1 ? 1 : -1
      all_res = all_res.select { |res| ((res.first / res.last) >= 1 ? 1 : -1) == current_ratio }.sort

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
  end
end
# Constant containing all the PSDK Config
PSDK_CONFIG = ScriptLoader::PSDKConfig.allocate
