module Battle
  class Logic
    class BattleInfo
      # Name of the background according to their processed zone_type
      BACKGROUND_NAMES = %w[back_building back_grass back_tall_grass back_taller_grass back_cave
                            back_mount back_sand back_pond back_sea back_under_water back_ice back_snow]
      # List of of suffix for the timed background. Order is morning, day, sunset, night.
      # @return [Array<Array<String>>]
      TIMED_BACKGROUND_SUFFIXES = [%w[morning day], %w[day], %w[sunset night], %w[night]]
      # Get the background name
      # @return [String]
      attr_accessor :background_name

      # Get the correct background name to display
      # @param prefix [String, nil] prefix to add to all suggested background
      # @param block [Proc] proc responsive of telling weither the filename param exists and can be used
      # @yieldparam background_name [String]
      # @yieldreturn [Boolean]
      # @return [String] found background name
      def find_background_name_to_display(prefix = nil, &block)
        suggestions = background_name_suggestions(prefix)
        log_debug("Background #{prefix} suggestions: #{suggestions.join(', ')}")
        return suggestions.find(&block) || suggestions.last
      end

      private

      # Get all the possible background name to display
      # @param prefix [String, nil] prefix to add to all suggested background
      # @return [Array<string>]
      def background_name_suggestions(prefix)
        return [
          *background_name_suggestions_for("#{prefix}#{@background_name}"),
          *background_name_suggestions_for("#{prefix}#{system_tag_background_name}")
        ].uniq
      end

      # Get the suggestion for a background name
      # @param background_name [String]
      # @return [Array<string>]
      def background_name_suggestions_for(background_name)
        return nil unless background_name
        return nil if background_name.empty?

        timed = timed_background_names(background_name)
        return [
          *(timed && timed.flat_map { |name| trainer_background_name(name) }),
          *timed,
          *trainer_background_name(background_name),
          background_name
        ]
      end

      # Function that returns the possible background names depending on the time
      # @param background_name [String]
      # @return [Array<String>, nil]
      def timed_background_names(background_name)
        return nil unless $game_switches[Yuki::Sw::TJN_Enabled] && $game_switches[Yuki::Sw::Env_CanFly]

        mapper = proc { |suffix| "#{background_name}_#{suffix}"}
        if $game_switches[Yuki::Sw::TJN_MorningTime]
          return TIMED_BACKGROUND_SUFFIXES[0].map(&mapper)
        elsif $game_switches[Yuki::Sw::TJN_DayTime]
          return TIMED_BACKGROUND_SUFFIXES[1].map(&mapper)
        elsif $game_switches[Yuki::Sw::TJN_SunsetTime]
          return TIMED_BACKGROUND_SUFFIXES[2].map(&mapper)
        elsif $game_switches[Yuki::Sw::TJN_NightTime]
          return TIMED_BACKGROUND_SUFFIXES[3].map(&mapper)
        end

        return nil
      end

      # Function that returns the background name based on the system tag
      # @return [String]
      def system_tag_background_name
        zone_type = $env.get_zone_type
        zone_type += 1 if zone_type > 0 || $env.grass?
        return BACKGROUND_NAMES[zone_type].to_s
      end

      # Function that returns the background name based on the trainer names
      # @param background_name [String]
      # @return [Array<String>]
      def trainer_background_name(background_name)
        return @battlers[1].uniq.map { |suffix| "#{background_name}_#{suffix}" }
      end
    end
  end
end
