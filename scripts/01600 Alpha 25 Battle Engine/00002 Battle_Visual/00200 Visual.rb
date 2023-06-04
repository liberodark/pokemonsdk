module Battle
  # Class that manage all the thing that are visually seen on the screen
  class Visual
    # @return [Hash] List of the parallel animation
    attr_reader :parallel_animations

    # @return [Array] List of the animation
    attr_reader :animations

    # @return [Viewport] the viewport used to show the sprites
    attr_reader :viewport

    # @return [Viewport] the viewport used to show some UI part
    attr_reader :viewport_sub

    # @return [Array] the element to dispose on #dispose
    attr_reader :to_dispose

    # Create a new visual instance
    # @param scene [Scene] scene that hold the logic object
    def initialize(scene)
      @scene = scene
      @screenshot = take_snapshot
      # All the battler by bank
      @battlers = {}
      # All the bars by bank
      @info_bars = {}
      # All the team info bar by bank
      @team_info = {}
      # All the ability bar by bank
      # @type [Hash{ Integer => Array<BattleUI::AbilityBar> }]
      @ability_bars = {}
      # All the item bar by bank
      # @type [Hash{ Integer => Array<BattleUI::ItemBar> }]
      @item_bars = {}
      # All the animation currently being processed (automatically removed)
      @animations = []
      # All the animatable object
      @animatable = []
      # All the parallel animations (manually removed)
      @parallel_animations = {}
      # All the thing to dispose on #dispose
      @to_dispose = []
      # Is the visual locking the update of the battle
      @locking = false
      # Create all the sprites
      create_graphics
      create_battle_animation_handler
      @viewport&.sort_z
    end

    # Safe to_s & inspect
    def to_s
      format('#<%<class>s:%<id>08X>', class: self.class, id: __id__)
    end
    alias inspect to_s

    # Update the visuals
    def update
      @animations.each(&:update)
      @animations.delete_if(&:done?)
      @parallel_animations.each_value(&:update)
      @gif_container&.update(@background.bitmap)
      update_battlers
      update_info_bars
      update_team_info
      update_ability_bars
      update_item_bars
    end

    # Dispose the visuals
    def dispose
      @to_dispose.each(&:dispose)
      @animations.clear
      @parallel_animations.clear
      @viewport.dispose
      @viewport_sub.dispose
    end

    # Tell if the visual are locking the battle update (for transition purpose)
    def locking?
      @locking
    end

    # Unlock the battle scene
    def unlock
      @locking = false
    end

    # Lock the battle scene
    def lock
      if block_given?
        raise 'Race condition' if locking?

        @locking = true
        yield
        return @locking = false
      end
      @locking = true
    end

    # Display animation & stuff like that by updating the scene
    # @yield [] yield the given block without argument
    # @note this function raise if the visual are not locked
    def scene_update_proc
      raise 'Unlocked visual while trying to update scene!' unless @locking
      yield
      @scene.update
      Graphics.update
    end

    # Wait for all animation to end (non parallel one)
    def wait_for_animation
      # log_debug('Entring wait_for_animation') # uncomment for deep debug
      was_locked = @locking
      lock unless was_locked
      scene_update_proc { update } until @animations.all?(&:done?) && @animatable.all?(&:done?)
      unlock unless was_locked
      # log_debug('Leaving wait_for_animation') # uncomment for deep debug
    end

    # Snap all viewports to bitmap
    # @return [Array<Texture>]
    def snap_to_bitmaps
      return [@viewport, @viewport_sub].map(&:snap_to_bitmap)
    end

    private

    # Create all the graphics for the visuals
    def create_graphics
      create_viewport
      create_background
      create_battlers
      create_player_choice
      create_skill_choice
    end

    # Create the Visual viewport
    def create_viewport
      @viewport = Viewport.create(:main, 500)
      @viewport.extend(Viewport::WithToneAndColors)
      @viewport.shader = Shader.create(:map_shader)
      @viewport_sub = Viewport.create(:main, 501)
    end

    # Create the default background
    def create_background
      bg_name = background_name
      if Yuki::GifReader.exist?("#{bg_name}.gif", :battleback)
        @background = Sprite.new(viewport)
        @gif_container = Yuki::GifReader.create("#{bg_name}.gif", :battleback)
        @background.bitmap = Bitmap.new(@gif_container.width, @gif_container.height)
        @background.x = @background.y = 0
        @to_dispose << @background.bitmap
      else
        @background = ShaderedSprite.new(@viewport).set_bitmap(bg_name, :battleback)
      end
    end

    # Return the background name according to the current state of the player
    # @return [String]
    def background_name
      @scene.battle_info.find_background_name_to_display do |filename|
        next RPG::Cache.battleback_exist?(filename) || Yuki::GifReader.exist?("#{filename}.gif", :battleback)
      end
    end

    # Create the battler sprites (Trainer + Pokemon)
    def create_battlers
      infos = @scene.battle_info
      (logic = @scene.logic).bank_count.times do |bank|
        # create the trainer sprites
        infos.battlers[bank].each_with_index do |battler, position|
          sprite = BattleUI::TrainerSprite.new(@viewport, @scene, battler, bank, position, infos)
          store_battler_sprite(bank, -position - 1, sprite)
        end
        # Create the Pokemon sprites
        infos.vs_type.times do |position|
          sprite = BattleUI::PokemonSprite.new(@viewport, @scene)
          sprite.pokemon = logic.battler(bank, position)
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

    # Update the battler sprites
    def update_battlers
      @battlers.each_value do |battlers|
        battlers.each_value(&:update)
      end
    end

    # Update the info bars
    def update_info_bars
      @info_bars.each_value do |info_bars|
        info_bars.each(&:update)
      end
    end

    # Create an ability bar
    # @param bank [Integer]
    # @param position [Integer]
    def create_ability_bar(bank, position)
      @ability_bars[bank] ||= []
      @ability_bars[bank][position] = sprite = BattleUI::AbilityBar.new(@viewport_sub, @scene, bank, position)
      @animatable << sprite
      sprite.go_out(-3600)
    end

    # Update the Ability bars
    def update_ability_bars
      @ability_bars.each_value do |ability_bars|
        ability_bars.each(&:update)
      end
    end

    # Update the item bars
    def update_item_bars
      @item_bars.each_value do |item_bars|
        item_bars.each(&:update)
      end
    end

    # Create an item bar
    # @param bank [Integer]
    # @param position [Integer]
    def create_item_bar(bank, position)
      @item_bars[bank] ||= []
      @item_bars[bank][position] = sprite = BattleUI::ItemBar.new(@viewport_sub, @scene, bank, position)
      @animatable << sprite
      sprite.go_out(-3600)
    end

    # Create the info bar for a bank
    # @param bank [Integer]
    # @param position [Integer]
    def create_info_bar(bank, position)
      info_bars = (@info_bars[bank] ||= [])
      pokemon = @scene.logic.battler(bank, position)
      info_bars[position] = sprite = BattleUI::InfoBar.new(@viewport_sub, @scene, pokemon, bank, position)
      @animatable << sprite
    end

    # Create the Trainer Party Ball
    # @param bank [Integer]
    def create_team_info(bank)
      @team_info[bank] = sprite = BattleUI::TrainerPartyBalls.new(@viewport_sub, @scene, bank)
      @animatable << sprite
    end

    # Update the team info
    def update_team_info
      @team_info.each_value(&:update)
    end

    # Create the player choice
    def create_player_choice
      @player_choice_ui = BattleUI::PlayerChoice.new(@viewport_sub, @scene)
    end

    # Create the skill choice
    def create_skill_choice
      @skill_choice_ui = BattleUI::SkillChoice.new(@viewport_sub, @scene)
    end

    # Create the battle animation handler
    def create_battle_animation_handler
      PSP.make_sprite(@viewport)
      @move_animator = PSP
    end

    # Take a snapshot
    # @return [Texture]
    def take_snapshot
      $scene.snap_to_bitmap
    end
  end
end
