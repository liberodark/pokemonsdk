module BattleUI
  class Battleback3D < ShaderedSprite

    MARGIN_X = 64
    MARGIN_Y = 68

    # Get the scene linked to this object
    # @return [Battle::Scene]
    attr_reader :scene

    # Create a new BattleBack3D
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    def initialize(viewport, scene)
      super(viewport)
      @viewport = viewport
      @battleback_list = []
      @path = resource_path
      create_graphics
      create_animations
      @animations.each(&:start)
    end

    # Set the position of the sprite
    # @param x [Numeric]
    # @param y [Numeric]
    # @param z [Numeric] z position of the sprite (1 is most likely at scale, 2 is smaller and 0 is illegal)
    # @return [self]
    def set_position(x, y, z = 1)
      super(x, y)
      self.z = z if z
    end

    # Set the z position of the sprite
    # @param z [Numeric]
    def z=(z)
      super
      shader.set_float_uniform('z', z)
    end

    # Return an Array containing the elements of the background
    def battleback_sprite3D
      return @battleback_list
    end

    # Update the background Elements (especially the animated elements)
    def update_battleback
      @animations.each(&:update)
    end

    # Create all the graphic elements for the BattleBack
    def create_graphics
    end

    # Create all the animations for the graphics element in an array of Yuki::Animation::TimedAnimation
    def create_animations
      @animations = []
    end

    private


    # Add an element to the background
    # @param path [String] folder where the element is located
    # @param name [String] name of the ressource
    # @param x [Numeric]
    # @param y [Numeric]
    # @param z [Numeric] z position of the sprite (1 is most likely at scale, 2 is smaller, 0 is illegal)
    # @param zoom [Numeric] zoom applied to Sprite to compensate for z
    # @return [BattleUI::Sprite3D]
    def add_battleback_element(path, name, x=-(Graphics.width/2 + MARGIN_X), y=-(Graphics.height/2 + MARGIN_Y), z=1, zoom=1)
      bg_name = timed_background_names(path + name)
      sprite = Sprite3D.new(@viewport).set_bitmap(bg_name, :battleback)
      sprite.set_position(x, y)
      sprite.zoom = zoom
      sprite.z = z
      @battleback_list.append(sprite)
      return sprite
    end

    # Function that returns the possible background names depending on the time
    # @param name [String]
    # @return [Array<String>, nil]
    def timed_background_names(sprite_name)
      return sprite_name unless $game_switches[Yuki::Sw::TJN_Enabled] && $game_switches[Yuki::Sw::Env_CanFly]

      suffixes = nil

      if $game_switches[Yuki::Sw::TJN_MorningTime]
        suffixes = Battle::Logic::BattleInfo::TIMED_BACKGROUND_SUFFIXES[0]
      elsif $game_switches[Yuki::Sw::TJN_DayTime]
        suffixes = Battle::Logic::BattleInfo::TIMED_BACKGROUND_SUFFIXES[1]
      elsif $game_switches[Yuki::Sw::TJN_SunsetTime]
        suffixes = Battle::Logic::BattleInfo::TIMED_BACKGROUND_SUFFIXES[2]
      elsif $game_switches[Yuki::Sw::TJN_NightTime]
        suffixes = Battle::Logic::BattleInfo::TIMED_BACKGROUND_SUFFIXES[3]
      end

      return sprite_name unless suffixes

      bg_name = "#{sprite_name}_#{suffixes.first}"
      return RPG::Cache.battleback_exist?(bg_name) ? bg_name : sprite_name
    end

    # Return the path for the resources, define it inside your Battleback Class
    def resource_path
      'animated_camera/'
    end
  end
end
