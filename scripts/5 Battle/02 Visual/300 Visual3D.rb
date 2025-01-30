module UI
  class Sprite3D < ShaderedSprite
    prepend Fake3D::Sprite3D

  end
end

module BattleUI
  class Sprite3D < ShaderedSprite
    prepend Fake3D::Sprite3D

    def z=(z)
      super(50-z)
      z = 1
      shader.set_float_uniform('z', z)
    end
  end
end

module Battle
  # Tell if Visual3D should be used
  BATTLE_CAMERA_3D = false

  # Class that manage all the things that are visually seen on the screen used only when BATTLECAMERA is true
  class Visual3D < Visual
    # Return half of the width of the default resolution
    HALF_WIDTH = 160

    # Return half of the height of the default resolution
    HALF_HEIGHT = 120

    # Camera of the battle
    # @return [Fake3D::Camera]
    attr_accessor :camera

    # Camera Positionner of the camera
    # @return [Fake3D::Camera]
    attr_accessor :camera_positionner

    # @return Array of the sprite applied to the camera
    attr_accessor :sprites3D

    # Create a new visual instance
    # @param scene [Scene] scene that hold the logic object
    def initialize(scene)
      # Store all the sprites for the camera
      @sprites3D = []
      super
      # All additions relative to Camera
      @camera.apply_to(@sprites3D + @background.battleback_sprite3D)
    end

    # Create the Visual viewport
    def create_viewport
      @viewport = Viewport.create(:main, 500)
      @viewport.extend(Viewport::WithToneAndColors)
      @viewport.shader = Shader.create(:map_shader)
      @viewport_sub = Viewport.create(:main, 501)
      create_cameras
    end

    # Create the camera and the camera_positionner
    def create_cameras
      @camera = Fake3D::Camera.new(viewport)
      @camera_positionner = CameraPositionner.new(@camera)
    end

    # Update the visuals
    def update
      super
      @sprites3D&.reject!(&:disposed?)
      @background.update_battleback
      update_camera
    end

    private

    # Create the default background
    def create_background
      case background_name
      when "back_grass"
        @background = BattleUI::BattleBackGrass.new(viewport, @scene)
      else
        @background = BattleUI::BattleBackGrass.new(viewport, @scene) # For the future create new Background
      end
    end

    # Create the battler sprites (Trainer + Pokemon)
    def create_battlers
      infos = @scene.battle_info
      (logic = @scene.logic).bank_count.times do |bank|
        # create the trainer sprites
        infos.battlers[bank].each_with_index do |battler, position|
          sprite = BattleUI::TrainerSprite3D.new(@viewport, @scene, battler, bank, position, infos)
          @sprites3D.append(sprite)
          store_battler_sprite(bank, -position - 1, sprite)
        end
        # Create the Pokemon sprites
        infos.vs_type.times do |position|
          sprite = BattleUI::PokemonSprite3D.new(@viewport, @scene, @camera, @camera_positionner)
          sprite.pokemon = logic.battler(bank, position)
          @sprites3D.append(sprite) unless sprite.pokemon.nil? 
          @sprites3D.append(sprite.shadow) unless sprite.pokemon.nil?
          @animatable << sprite
          store_battler_sprite(bank, position, sprite)
          create_info_bar(bank, position)
          create_ability_bar(bank, position)
          create_item_bar(bank, position)
        end
        # Create the Team Info
        create_team_info(bank)
      end
      hide_info_bars(true)
    end

    private

    # End of the show_player_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_player_choice_end(pokemon_index)
      @player_choice_ui.go_out
      @animations << @player_choice_ui
      start_center_animation
      if @player_choice_ui.result != :attack
        spc_stop_bouncing_animation(pokemon_index)
        wait_for_animation
      end
      @locking = false
    end

    # Begining of the show_player_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_player_choice_begin(pokemon_index)
      pokemon = @scene.logic.battler(0, pokemon_index)
      @locking = true
      @player_choice_ui.reset(@scene.logic.switch_handler.can_switch?(pokemon))
      if @player_choice_ui.out?
        @player_choice_ui.go_in
        @animations << @player_choice_ui
        wait_for_animation
      end
      start_camera_animation
      spc_show_message(pokemon_index)
      spc_start_bouncing_animation(pokemon_index)
    end

    # End of the skill_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_skill_choice_end(pokemon_index)
      spc_stop_bouncing_animation(pokemon_index)
      @skill_choice_ui.go_out
      @animations << @skill_choice_ui
      start_center_animation
      wait_for_animation
      @locking = false
    end
  end
end