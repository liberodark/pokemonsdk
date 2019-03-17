module Yuki
  # The script that manage tone of the screen
  # @author Nuri Yuri
  module TJN
    # The different tones
    TONE = [
      Tone.new(-85, -85, -10, 0), # Night
      Tone.new(-17, -51, -34, 0), # Evening
      Tone.new(-60, -60, -10, 0), # Morning / Night
      Tone.new(0, 0, 0, 0), # Day
      Tone.new(17, -17, -34, 0) # Dawn
    ]
    # The time when the tone changes
    TIME = [22, 19, 11, 7]
    # The number of frame that makes 1 minute in Game time
    MIN_FRAMES = 600
    @timer = 0
    @forced = false
    @current_tone = 0

    module_function

    # Update the tone of the screen and the game time
    def update
      @timer < MIN_FRAMES ? @timer += 1 : update_time
      update_tone if @forced
    end

    # Update the game time
    # @note If the game switch Yuki::Sw::TJN_NoTime is on, there's no time update.
    # @note If the game switch Yuki::Sw::TJN_RealTime is on, the time is the computer time
    def update_time
      @timer = 0
      return if $game_switches[Sw::TJN_NoTime]
      # If we use the real time
      if $game_switches[Sw::TJN_RealTime]
        v = 0
        update_tone if update_real_time
      else
        v = ($game_variables[Var::TJN_Min] += 1)
      end
      # Trigger an on_update event for Yuki::TJN
      Scheduler.start(:on_update, self)
      # If an hour passed
      if v >= 60
        $game_variables[Var::TJN_Min] = 0
        v = $game_variables[Var::TJN_Hour] += 1
        # If a day passed
        if v >= 24
          $game_variables[Var::TJN_Hour] = 0
          v = $game_variables[Var::TJN_WDay] += 1
          # If a week passed
          if v >= 8
            $game_variables[Var::TJN_WDay] = 1
            v = $game_variables[Var::TJN_Week] += 1
            $game_variables[Var::TJN_Week] = 0 if v >= 0xffff
          end
          v = $game_variables[Var::TJN_MDay] += 1
          # A month will be about 28 days
          if v >= 29
            $game_variables[Var::TJN_MDay] = 1
            v = $game_variables[Var::TJN_Month] += 1
            # A year will be about 13 months
            $game_variables[Var::TJN_Month] = 1 if v >= 14
          end
        end
        update_tone
      end
    end

    # Update the real time values
    # @return [Boolean] if update_time should call update_tone
    def update_real_time
      last_hour = $game_variables[Var::TJN_Hour]
      @timer = MIN_FRAMES - 60 if MIN_FRAMES > 60
      time = Time.new
      $game_variables[Var::TJN_Min] = time.min
      $game_variables[Var::TJN_Hour] = time.hour
      $game_variables[Var::TJN_WDay] = time.wday
      $game_variables[Var::TJN_MDay] = time.day
      $game_variables[Var::TJN_Month] = time.month
      return last_hour != time.hour
    end

    # Update the tone of the screen
    # @note if the game switch Yuki::Sw::TJN_Enabled is off, the tone is not updated
    def update_tone
      t = (@forced == true ? 0 : 20)
      @forced = false
      return unless $game_switches[Sw::TJN_Enabled]
      unless (day_tone = $game_switches[Sw::Env_CanFly])
        $game_screen.start_tone_change(TONE[@current_tone = 3], t)
      end
      day_tone = false if $env.sunny? # Zenith adds an other tone
      v = $game_variables[Var::TJN_Hour]
      if v >= TIME[0]
        $game_screen.start_tone_change(TONE[@current_tone = 0], t) if day_tone
        update_switches_and_variables(Sw::TJN_NightTime, 0)
      elsif v >= TIME[1]
        $game_screen.start_tone_change(TONE[@current_tone = 1], t) if day_tone
        update_switches_and_variables(Sw::TJN_SunsetTime, 1)
      elsif v >= TIME[2]
        $game_screen.start_tone_change(TONE[@current_tone = 3], t) if day_tone
        update_switches_and_variables(Sw::TJN_DayTime, 3)
      elsif v >= TIME[3]
        $game_screen.start_tone_change(TONE[@current_tone = 4], t) if day_tone
        update_switches_and_variables(Sw::TJN_MorningTime, 2)
      else
        $game_screen.start_tone_change(TONE[@current_tone = 2], t) if day_tone
        update_switches_and_variables(Sw::TJN_NightTime, 0)
      end
      $game_map.need_refresh = true
      ::Scheduler.start(:on_hour_update, $scene.class)
    end

    # List of the switch name used by the TJN system (it's not defined here so we use another access)
    TJN_SWITCH_LIST = %i[TJN_NightTime TJN_DayTime TJN_MorningTime TJN_SunsetTime]
    # Update the state of the switches and the tone variable
    # @param switch_id [Integer] ID of the switch that should be true (all the other will be false)
    # @param variable_value [Integer] new value of $game_variables[Var::TJN_Tone]
    def update_switches_and_variables(switch_id, variable_value)
      $game_variables[Var::TJN_Tone] = variable_value
      TJN_SWITCH_LIST.each do |switch_name|
        switch_index = Sw.const_get(switch_name)
        $game_switches[switch_index] = switch_index == switch_id
      end
    end

    # Force the next update to update the tone
    # @param value [Boolean] true to force the next update to update the tone
    def force_update_tone(value = true)
      @forced = value
    end

    # Return the current tone
    # @return [Tone]
    def current_tone
      $game_switches[Sw::TJN_Enabled] ? TONE[@current_tone] : TONE[3]
    end
  end
end
