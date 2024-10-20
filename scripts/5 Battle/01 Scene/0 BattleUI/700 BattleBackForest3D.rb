module BattleUI
  # Here we only deal with the method for creating graphic elements associated with a Battleback when BATTLE_CAMERA_3D is activated. This is an example, so feel free to create your own.
  # Reminder : All the coordinates are calculated from the center of your Viewport which is :
  # x = Graphics.width and y = Graphics.height
  class BattleBackGrass < Battleback3D
    # Function that define the Battleback
    # To create your own Battleback you need to follow the same pattern
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    def initialize(viewport, scene)
      super
    end

    # Create all the graphic elements for the BattleBack
    def create_graphics
      # Ground Sprites
      @background = add_battleback_element(@path, "field")
      @ground = add_battleback_element(@path, "ground")

      # Sky Sprites
      @sky = add_battleback_element(@path, "sky")
      @cloud2 = add_battleback_element(@path, "cloud2")
      @cloud1 = add_battleback_element(@path, "cloud1")
      # Make the clouds invisible during night time
      if $game_switches[Yuki::Sw::TJN_NightTime]
        @cloud2.visible = false
        @cloud1.visible = false
      end

      # Background elements
      @trees1 = add_battleback_element(@path, "trees1")
      @trees2 = add_battleback_element(@path, "trees2")
    end

    # Create all the animations for the graphics element in an array of Yuki::Animation::TimedAnimation
    def create_animations
      @animations = []
      start_x = -(Graphics.width/2 + MARGIN_X)
      @animations << create_animation_cloud(@cloud1, start_x, Graphics.width/2 + MARGIN_X, 60)
      @animations << create_animation_cloud(@cloud2, start_x, 2 * start_x, 60)
      @animations.each(&:start)
    end

    # create the animation for a cloud, this animation loops automatically, so it returns to start_x
    # @param element [BattleUI::Sprite3D] element from the backgound to be animated
    # @param start_x [Integer] x coordinates for the start of the animation
    # @param final_x [Integer] x coordinates for the target of the animation
    # @param duration [Float] duration of the animation in seconds (must be superior to 2.0)
    # @return [Yuki::Animation::TimedAnimation] animation for the cloud
    def create_animation_cloud(element, start_x, final_x, duration)
      return nil unless duration > 2.0
      duration_animation = (duration - 2.0) / 2.0
      animation  = Yuki::Animation::TimedLoopAnimation.new(duration)
      animation.play_before(Yuki::Animation.wait(1))
      animation.play_before(Yuki::Animation.move(duration_animation, element, start_x, element.y, final_x, element.y))
      animation.play_before(Yuki::Animation.wait(1))
      animation.play_before(Yuki::Animation.move(duration_animation, element, final_x, element.y, start_x, element.y))
      animation.resolver = self
      return animation
    end

    # Return the path for the resources
    def resource_path
      "animated_camera/BattleBack Forest/"
    end
  end
end
