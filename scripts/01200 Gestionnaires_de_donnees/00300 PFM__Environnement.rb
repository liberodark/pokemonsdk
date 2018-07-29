#encoding: utf-8

module PFM
  # Environment management (Weather, Zone, etc...)
  #
  # The global Environment object is stored in $env and $pokemon_party.env
  # @author Nuri Yuri
  class Environnement
    include GameData::SystemTags
    # The master zone (zone that show the pannel like city, unlike house of city)
    # @note Master zone are used inside Pokemon data
    # @return [Integer]
    attr_reader :master_zone
    # Last visited map ID
    # @return [Integer]
    attr_reader :last_map_id
    # Create a new Environnement object
    def initialize
      @weather = 0
      @battle_weather = 0
      @duration = 1/0.0
      @zone = 0 #>Indicateur de la zone dans lequel le héros se trouve
      @master_zone = 0
      @warp_zone = 0
      @last_map_id = 0
      @visited_zone = Array.new
      @deleted_events = Hash.new
    end
    # Apply a new weather to the current environment
    # @param id [Integer] ID of the weather : 0 = None, 1 = Rain, 2 = Sun/Zenith, 3 = Darud Sandstorm, 4 = Hail, 5 = Foggy
    # @param duration [Integer, nil] the total duration of the weather (battle), nil = never stops
    def apply_weather(id, duration=nil)
      @battle_weather = id
      @weather = id unless $game_temp.in_battle and !$game_switches[::Yuki::Sw::MixWeather]
      @duration=(duration ? duration : 1/0.0)
      ajust_weather_switches
    end
    # Ajust the weather switch to put the game in the correct state
    def ajust_weather_switches
      weather = current_weather
      $game_switches[::Yuki::Sw::WT_Rain] = (weather == 1)
      $game_switches[::Yuki::Sw::WT_Sunset] = (weather == 2)
      $game_switches[::Yuki::Sw::WT_Sandstorm] = (weather == 3)
      $game_switches[::Yuki::Sw::WT_Snow] = (weather == 4)
      $game_switches[::Yuki::Sw::WT_Fog] = (weather == 5)
    end
    # Return the current weather duration
    # @return [Numeric] can be Float::INFINITY
    def get_weather_duration
      return @duration
    end
    # Decrease the weather duration, set it to normal (none = 0) if the duration is less than 0
    # @return [Boolean] true = the weather stopped
    def decrease_weather_duration
      @duration-=1 if @duration > 0
      if(@duration<=0 and @battle_weather != 0)
        apply_weather(0,0)
        return true
      end
      return false
    end
    # Return the current weather id according to the game state (in battle or not)
    # @return [Integer]
    def current_weather
      return $game_temp.in_battle ? @battle_weather : @weather
    end
    # Is it rainning?
    # @return [Boolean]
    def rain?
      return false if $game_temp.in_battle and ::BattleEngine.state[:air_lock]
      return current_weather==1
    end
    # Is it sunny?
    # @return [Boolean]
    def sunny?
      return false if $game_temp.in_battle and ::BattleEngine.state[:air_lock]
      return current_weather==2
    end
    # Duuuuuuuuuuuuuuuuuuuuuuun
    # Dun dun dun dun dun dun dun dun dun dun dun dundun dun dundundun dun dun dun dun dun dun dundun dundun
    # @return [Boolean]
    def sandstorm?
      return false if $game_temp.in_battle and ::BattleEngine.state[:air_lock]
      return current_weather==3
    end
    # Does it hail ?
    # @return [Boolean]
    def hail?
      return false if $game_temp.in_battle and ::BattleEngine.state[:air_lock]
      return current_weather==4
    end
    # Is it foggy ?
    # @return [Boolean]
    def fog?
      return false if $game_temp.in_battle and ::BattleEngine.state[:air_lock]
      return current_weather==5
    end
    # Is the weather normal
    # @return [Boolean]
    def normal?
      return false if $game_temp.in_battle and ::BattleEngine.state[:air_lock]
      return current_weather==0
    end
    # Is the player inside a building (and not on a systemtag)
    # @return [Boolean]
    def building?
      return (!$game_switches[Yuki::Sw::Env_CanFly] and $game_player.system_tag==0)
    end
    # Update the zone informations, return the ID of the zone when the player enter in an other zone
    # 
    # Add the zone to the visited zone Array if the zone has not been visited yet
    # @return [Integer, false] false = player was in the zone
    def update_zone
      return false if @last_map_id==$game_map.map_id
      @last_map_id = map_id = $game_map.map_id
      last_zone=@zone
      #>Recherche de la zone actuelle
      $game_data_zone.each_with_index do |d, i|
        next unless d
        #if(map_id==d.map_id)
        if(d.map_included?(map_id))
          @zone = i
          @warp_zone = i if(d.warp_x and d.warp_y)
          @master_zone = i if d.panel_id and d.panel_id > 0
          @visited_zone<<i unless @visited_zone.include?(i)
          $game_switches[Yuki::Sw::Env_CanFly]=(!d.warp_disallowed and d.fly_allowed)
          $game_switches[Yuki::Sw::Env_CanDig]=(!d.warp_disallowed and !d.fly_allowed)
          #apply_weather(d.forced_weather) if d.forced_weather
          if d.forced_weather
            if d.forced_weather == 0
              $game_screen.weather(0, 0, 40)
            else
              $game_screen.weather(0, 9, 40, psdk_weather: d.forced_weather)
            end
          end
          break
        end
      end
      return false if last_zone==@zone
      return @zone
    end
    # Reset the zone informations to get the zone id with update_zone (Panel display)
    def reset_zone
      @last_map_id = -1
      @zone = -1
    end
    # Return the current zone in which the player is
    # @return [Integer] the zone ID in the database
    def get_current_zone
      return @zone
    end
    # Return the zone data in which the player is
    # @return [GameData::Map]
    def get_current_zone_data
      $game_data_zone[@zone]
    end
    # Return the warp zone ID (where the player will teleport with skills)
    # @return [Integer] the ID of the zone in the database
    def get_warp_zone
      return @warp_zone
    end
    # Get the zone data in the worldmap
    # @param x [Integer] the x position of the zone in the World Map
    # @param y [Integer] the y position of the zone in the World Map
    # @return [GameData::Map, nil] nil = no zone there
    def get_zone(x,y)
      return nil unless $game_data_map[x]
      z=$game_data_map[x][y]
      return $game_data_zone[z] if(z)
      return nil
    end
    # Return the zone coordinate in the worldmap
    # @param zone_id [Integer] id of the zone in the database
    # @return [Array(Integer, Integer)] the x,y coordinates
    def get_zone_pos(zone_id)
      return 0,0 unless zone=$game_data_zone[zone_id]
      return zone.pos_x,zone.pos_y if(zone.pos_x and zone.pos_y)
      $game_data_map.each_index do |x|
        next unless $game_data_map[x]
        $game_data_map[x].each_index do |y|
          return x,y if($game_data_map[x][y]==zone_id)
        end
      end
      return 0,0
    end
    # Check if a zone has been visited
    # @param zone [Integer, GameData::Map] the zone id in the database or the zone
    # @return [Boolean]
    def visited_zone?(zone)
      if(zone.class==GameData::Map)
        z=$game_data_zone.index(zone)
        unless z
          $game_data_zone.each_index do |i|
            if($game_data_zone[i].map_id==zone.map_id)
              z=i
              break
            end
          end
        end
        zone=z
      end
      return @visited_zone.include?(zone)
    end
    # Is the player standing in grass ?
    # @return [Boolean]
    def grass?
      return ($game_switches[Yuki::Sw::Env_CanFly] and $game_player.system_tag==0)
    end
    # Is the player standing in tall grass ?
    # @return [Boolean]
    def tall_grass?
      return $game_player.system_tag == TGrass
    end
    # Is the player standing in taller grass ?
    # @return [Boolean]
    def very_tall_grass?
      return $game_player.system_tag == TTallGrass
    end
    # Is the player in a cave ?
    # @return [Boolean]
    def cave?
      return $game_player.system_tag == TCave
    end
    # Is the player on a mount ?
    # @return [Boolean]
    def mount?
      return $game_player.system_tag == TMount
    end
    # Is the player on sand ?
    # @return [Boolean]
    def sand?
      tag = $game_player.system_tag
      return (tag == TSand or tag == TWetSand)
    end
    # Is the player on a pond/river ?
    # @return [Boolean]
    def pond? # Etang / Rivière etc...
      return $game_player.system_tag == TPond
    end
    # Is the player on a sea/ocean ?
    # @return [Boolean]
    def sea?
      return $game_player.system_tag == TSea
    end
    # Is the player underwater ?
    # @return [Boolean]
    def under_water?
      return $game_player.system_tag == TUnderWater
    end
    # Is the player on ice ?
    # @return [Boolean]
    def ice?
      return $game_player.system_tag == TIce
    end
    # Is the player on snow or ice ?
    # @return [Boolean]
    def snow?
      tag = $game_player.system_tag
      return (tag == TSnow or tag == TIce) #>ice fera comme snow pour les attaques.
    end
    # Return the zone type
    # @param ice_prio [Boolean] when on snow for background, return ice ID if player is on ice
    # @return [Integer] 1 = tall grass, 2 = taller grass, 3 = cave, 4 = mount, 5 = sand, 6 = pond, 7 = sea, 8 = underwater, 9 = snow, 10 = ice, 0 = building
    def get_zone_type(ice_prio = false)
      if tall_grass?
        return 1
      elsif very_tall_grass?
        return 2
      elsif cave?
        return 3
      elsif mount?
        return 4
      elsif sand?
        return 5
      elsif pond?
        return 6
      elsif sea?
        return 7
      elsif under_water?
        return 8
      elsif snow?
        return ((ice_prio and ice?) ? 10 : 9)
      elsif ice?
        return 10
      else
        return 0
      end
    end
    # Convert a system_tag to a zone_type
    # @param system_tag [Integer] the system tag
    # @return [Integer] same as get_zone_type
    def convert_zone_type(system_tag)
      case system_tag
      when TGrass
        return 1
      when TTallGrass
        return 2
      when TCave
        return 3
      when TMount
        return 4
      when TSand
        return 5
      when TPond
        return 6
      when TSea
        return 7
      when TUnderWater
        return 8
      when TSnow
        return 9
      when TIce
        return 10
      else
        return 0
      end
    end
    # Is it night time ?
    # @return [Boolean]
    def night?
      return $game_switches[::Yuki::Sw::TJN_NightTime]
    end
    # Is it day time ?
    # @return [Boolean]
    def day?
      return $game_switches[::Yuki::Sw::TJN_DayTime]
    end
    # Is it morning time ?
    # @return [Boolean]
    def morning?
      return $game_switches[::Yuki::Sw::TJN_MorningTime]
    end
    # Is it sunset time ?
    # @return [Boolean]
    def sunset?
      return $game_switches[::Yuki::Sw::TJN_SunsetTime]
    end
    # Can the player fish ?
    # @return [Boolean]
    def can_fish?
      tag = $game_player.front_system_tag
      return (tag == TPond or tag == TSea) 
    end
    # Set the delete state of an event
    # @param event_id [Integer] id of the event
    # @param map_id [Integer] id of the map where the event is
    # @param state [Boolean] new delete state of the event
    def set_event_delete_state(event_id, map_id = $game_map.map_id, state = true)
      deleted_events = @deleted_events = Hash.new unless deleted_events = @deleted_events
      deleted_events[map_id] = Hash.new unless deleted_events[map_id]
      deleted_events[map_id][event_id] = state
    end
    # Get the delete state of an event
    # @param event_id [Integer] id of the event
    # @param map_id [Integer] id of the map where the event is
    # @return [Boolean] if the event is deleted
    def get_event_delete_state(event_id, map_id = $game_map.map_id)
      return false unless deleted_events = @deleted_events
      return false unless deleted_events[map_id]
      return deleted_events[map_id][event_id]
    end
  end
end
