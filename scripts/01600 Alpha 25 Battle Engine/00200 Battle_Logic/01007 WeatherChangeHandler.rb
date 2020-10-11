module Battle
  class Logic
    # Handler responsive of answering properly weather changes requests
    class WeatherChangeHandler < ChangeHandlerBase
      include Hooks
      # Mapping between weather symbol & weather ID
      WEATHER_SYM_TO_ID = {
        none: 0,
        rain: 1,
        sunny: 2,
        sandstorm: 3,
        hail: 4,
        fog: 5
      }
      # Mapping between weather symbol & message_id
      WEATHER_SYM_TO_MSG = {
        none: 97,
        rain: 88,
        sunny: 87,
        sandstorm: 89,
        hail: 90,
        fog: 91
      }
      # Function telling if a weather can be applyied
      # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      # @return [Boolean]
      def weather_appliable?(weather_type)
        reset_prevention_reason
        last_weather = WEATHER_SYM_TO_ID.key($env.current_weather) || :none
        exec_hooks(WeatherChangeHandler, :weather_prevention, binding)
        return true
      rescue Hooks::ForceReturn => e
        return e.data
      end

      # Function that actually change the status
      # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      # @param nb_turn [Integer, nil] Number of turn, use nil for Infinity
      def weather_change(weather_type, nb_turn)
        last_weather = WEATHER_SYM_TO_ID.key($env.current_weather) || :none
        $env.apply_weather(WEATHER_SYM_TO_ID[weather_type] || 0, nb_turn)
        show_weather_message(last_weather, weather_type)
        exec_hooks(WeatherChangeHandler, :post_weather_change, binding)
      rescue Hooks::ForceReturn => e
        return e.data
      ensure
        @scene.visual.refresh_info_bar(target)
      end

      # Function that test if the change is possible and perform the change if so
      # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      # @param nb_turn [Integer, nil] Number of turn, use nil for Infinity
      def weather_change_with_process(weather_type, nb_turn)
        return process_prevention_reason unless status_appliable?(status, target, launcher, skill)

        weather_change(status, target, launcher, skill, message_overwrite: message_overwrite)
      end

      private

      # Show the weather message
      # @param last_weather [Symbol]
      # @param current_weather [Symbol]
      def show_weather_message(last_weather, current_weather)
        return if last_weather == current_weather

        if last_weather == :none
          @scene.display_message(parse_text(18, WEATHER_SYM_TO_MSG[current_weather]))
        elsif current_weather == :none
          @scene.display_message(parse_text(18, WEATHER_SYM_TO_MSG[current_weather]))
        end
      end

      class << self
        # Function that registers a weather_prevention hook
        # @param reason [String] reason of the weather_prevention registration
        # @yieldparam handler [WeatherChangeHandler]
        # @yieldparam weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @yieldparam last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @yieldreturn [:prevent, nil] :prevent if the status cannot be applied
        def register_weather_prevention_hook(reason)
          Hooks.register(WeatherChangeHandler, :weather_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:weather_type),
              hook_binding.local_variable_get(:last_weather)
            )
            force_return(false) if result == :prevent
          end
        end

        # Function that registers a post_weather_change hook
        # @param reason [String] reason of the post_weather_change registration
        # @yieldparam handler [WeatherChangeHandler]
        # @yieldparam weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @yieldparam last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def register_post_weather_change_hook(reason)
          Hooks.register(WeatherChangeHandler, :post_weather_change, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:weather_type),
              hook_binding.local_variable_get(:last_weather)
            )
          end
        end
      end
    end

    WeatherChangeHandler.register_weather_prevention_hook('PSDK prev weather: Duplicate weather') do |_, weather, prev|
      next if weather != prev

      next :prevent
    end

    WeatherChangeHandler.register_weather_prevention_hook('PSDK prev weather: Air Lock') do |handler, weather|
      next if weather == :none
      next unless (air_lock = handler.logic.all_alive_battlers.find { |battler| battler.ability_db_symbol == :air_lock })

      handler.prevent_change do
        handler.scene.visual.show_ability(air_lock)
      end
    end

    WeatherChangeHandler.register_weather_prevention_hook('PSDK prev weather: Cloud Nine') do |handler, weather|
      next if weather == :none
      next unless (cloud_nine = handler.logic.all_alive_battlers.find { |battler| battler.ability_db_symbol == :cloud_nine })

      handler.prevent_change do
        handler.scene.visual.show_ability(cloud_nine)
      end
    end

    WeatherChangeHandler.register_post_weather_change_hook('PSDK post weather: Ensure form switch on weather') do |handler|
      handler.logic.all_alive_battlers.each do |battler|
        next unless battler.form_calibrate(:weather)

        handler.scene.visual.show_switch_form_animation(battler)
      end
    end
  end
end
