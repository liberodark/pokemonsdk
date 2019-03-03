module Battle
  # Class that manage all the thing that are visually seen on the screen
  class Visual
    # Name of the background according to their processed zone_type
    BACKGROUND_NAMES = ["back_building", "back_grass", "back_tall_grass", "back_taller_grass",
                        "back_cave", "back_mount", "back_sand", "back_pond", "back_sea",
                        "back_under_water", "back_ice","back_snow"]

    # @return [Hash] List of the parallel animation
    attr_reader :parallel_animations

    # @return [Viewport] the viewport used to show the sprites
    attr_reader :viewport

    # Create a new visual instance
    # @param battle_scene [Scene] scene that hold the logic object
    def initialize(battle_scene)
      @battle_scene = battle_scene
      create_viewport
      create_background
      @screenshot = Graphics.snap_to_bitmap
      # All the battler by bank
      @battlers = Hash.new { {} }
      # All the bars by bank
      @info_bars = Hash.new { [] }
      # All the team info bar by bank
      @team_info = {}
      # All the animation currently being processed (automatically removed)
      @animations = []
      # All the parallel animations (manually removed)
      @parallel_animations = {}
      # Is the visual locking the update of the battle
      @locking = false
    end

    # Update the visuals
    def update
      @animations.delete_if(&:update)
      @parallel_animations.each_value(&:update)
    end

    # Dispose the visuals
    def dispose
      @animations.clear
      @parallel_animations.clear
      @viewport.dispose
    end

    # Tell if the visual are locking the battle update (for transition purpose)
    def locking?
      @locking
    end

    # Unlock the battle scene
    def unlock
      @locking = false
    end

    private

    # Create the Visual viewport
    def create_viewport
      @viewport = Viewport.create(:main, 500)
    end

    # Create the default background
    def create_background
      @background = Sprite.new(@viewport).set_bitmap(background_name, :battleback)
    end

    # Return the background name according to the current state of the player
    # @return [String]
    def background_name
      return $game_temp.battleback_name unless $game_temp.battleback_name.to_s.empty?
      zone_type = $env.get_zone_type
      zone_type += 1 if zone_type > 0 || $env.grass?
      return BACKGROUND_NAMES[zone_type].to_s
    end
  end
end
