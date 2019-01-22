#encoding: utf-8

module Yuki
  # The script that manage tone of the screen
  # @author Nuri Yuri
  module TJN
    # The different tones
    TONE = [Tone.new(-85, -85, -10, 0), #Nuit
    Tone.new(-17, -51, -34, 0), #Soir
    Tone.new(-60, -60, -10, 0), #Matin - Nuit
    Tone.new(0, 0, 0, 0), #Jour
    Tone.new(17,-17,-34,0)] #Aube
    # The time when the tone changes
    TIME=[22, 19, 11, 7]
    # The number of frame that makes 1 minute in Game time
    MIN_FRAMES = 600
    @timer = 0
    @forced = false
    module_function
    # Update the tone of the screen and the game time
    def update
      @timer<MIN_FRAMES ? @timer+=1 : update_time
      update_tone if @forced
    end
    # Update the game time
    # @note If the game switch Yuki::Sw::TJN_NoTime is on, there's no time update.
    # @note If the game switch Yuki::Sw::TJN_RealTime is on, the time is the computer time
    def update_time
      @timer=0
      return if $game_switches[Sw::TJN_NoTime]
      #> Si on utilise l'heure réelle
      if($game_switches[Sw::TJN_RealTime])
        v = 0
        @timer = MIN_FRAMES - 60 if MIN_FRAMES > 60
        time = Time.new
        $game_variables[Var::TJN_Min] = time.min
        $game_variables[Var::TJN_Hour] = time.hour
        $game_variables[Var::TJN_WDay] = time.wday
        $game_variables[Var::TJN_MDay] = time.day
        $game_variables[Var::TJN_Month] = time.month
        update_tone
      else
        v=$game_variables[Var::TJN_Min]+=1
      end
      #Berries::update
      Scheduler.start(:on_update, self)
      if v>=60
        $game_variables[Var::TJN_Min]=0
        v=$game_variables[Var::TJN_Hour]+=1
        if v>=24
          $game_variables[Var::TJN_Hour]=0
          v=$game_variables[Var::TJN_WDay]+=1
          if v>=8
            $game_variables[Var::TJN_WDay]=1
            v=$game_variables[Var::TJN_Week]+=1
            $game_variables[Var::TJN_Week]=0 if v>=0xffff
          end
          v=$game_variables[Var::TJN_MDay]+=1
          if(v>=30)
            $game_variables[Var::TJN_MDay]=1
            v=$game_variables[Var::TJN_Month]+=1
            $game_variables[Var::TJN_Month]=1 if v>=13
          end
        end
        update_tone
      end
    end
    # Update the tone of the screen
    # @note if the game switch Yuki::Sw::TJN_Enabled is off, the tone is not updated
    def update_tone
      return unless $game_switches[Sw::TJN_Enabled]
      t=(@forced==true ? 0 : 20)
      @forced=false
      unless day_tone = $game_switches[Sw::Env_CanFly]
        $game_screen.start_tone_change(TONE[3],t)
      end
      day_tone = false if $env.sunny? #Zenith adds an other tone
      v=$game_variables[Var::TJN_Hour]
      if v>=TIME[0]
        $game_screen.start_tone_change(TONE[0],t) if day_tone
        $game_variables[Var::TJN_Tone]=0
        $game_switches[Sw::TJN_NightTime]=true
        $game_switches[Sw::TJN_DayTime]=$game_switches[Sw::TJN_MorningTime]=
        $game_switches[Sw::TJN_SunsetTime]=false
      elsif v>=TIME[1]
        $game_screen.start_tone_change(TONE[1],t) if day_tone
        $game_variables[Var::TJN_Tone]=1
        $game_switches[Sw::TJN_SunsetTime]=true
        $game_switches[Sw::TJN_DayTime]=$game_switches[Sw::TJN_MorningTime]=
        $game_switches[Sw::TJN_NightTime]=false
      elsif v>=TIME[2]
        $game_screen.start_tone_change(TONE[3],t) if day_tone
        $game_variables[Var::TJN_Tone]=3
        $game_switches[Sw::TJN_DayTime]=true
        $game_switches[Sw::TJN_NightTime]=$game_switches[Sw::TJN_MorningTime]=
        $game_switches[Sw::TJN_SunsetTime]=false
      elsif v>=TIME[3]
        $game_screen.start_tone_change(TONE[4],t) if day_tone
        $game_variables[Var::TJN_Tone]=2
        $game_switches[Sw::TJN_MorningTime]=true
        $game_switches[Sw::TJN_DayTime]=$game_switches[Sw::TJN_SunsetTime]=
        $game_switches[Sw::TJN_NightTime]=false
      else
        $game_screen.start_tone_change(TONE[2],t) if day_tone
        $game_variables[Var::TJN_Tone]=0
        $game_switches[Sw::TJN_NightTime]=true
        $game_switches[Sw::TJN_DayTime]=$game_switches[Sw::TJN_MorningTime]=
        $game_switches[Sw::TJN_SunsetTime]=false
      end
      $game_map.need_refresh = true
      ::Scheduler.start(:on_hour_update, $scene.class)
    end
    # Force the next update to update the tone
    # @param v [Boolean] true to force the next update to update the tone
    def force_update_tone(v=true)
      @forced = v
    end
  end
end
