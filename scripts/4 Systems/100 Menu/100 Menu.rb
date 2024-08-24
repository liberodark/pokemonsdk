module GamePlay
  # Main menu UI
  class Menu < BaseCleanUpdate
    include MenuMixin
    # List of action according to call based on button index
    ACTION_LIST = []
    # List of condition to verify in order to show/activate a button
    CONDITION_LIST = []
    # List of button overwrites
    BUTTON_OVERWRITES = []
    # Entering - leaving animation offset
    ENTERING_ANIMATION_OFFSET = 150
    # Entering - leaving animation duration
    ENTERING_ANIMATION_DURATION = 15
    # Create a new menu
    def initialize
      super
      init_conditions
      init_indexes
      @call_skill_process = nil
      @index = $game_temp.last_menu_index
      @index = 0 if @index >= @image_indexes.size
      @max_index = @image_indexes.size - 1
      @quiting = false # Flag allowing to really quit
      @entering = true # Flag telling we're entering
      @in_save = false
      @mbf_type = @mef_type = :none if $scene.is_a?(Scene_Map)
    end

    # Create all the graphics
    def create_graphics
      create_viewport
      create_background
      create_buttons
      init_entering
    end

    # End of the scene
    def main_end
      super
      $game_temp.last_menu_index = @index
    end

    # Update the input interaction
    # @return [Boolean] if no input was detected
    def update_inputs
      return false if @entering || @quiting

      if index_changed(:@index, :UP, :DOWN, @max_index)
        play_cursor_se
        update_buttons
      elsif Input.trigger?(:A)
        action
      elsif Input.trigger?(:B)
        @quiting = true
      else
        return true
      end
      return false
    end

    # Update the mouse interaction
    # @param moved [Boolean] if the mouse moved
    # @return [Boolean]
    def update_mouse(moved)
      @buttons.each_with_index do |button, index|
        next unless button.simple_mouse_in?
        if moved
          last_index = @index
          @index = index
          if last_index != index
            update_buttons
            play_cursor_se
          end
        elsif Mouse.trigger?(:LEFT)
          @index = index
          update_buttons
          play_decision_se
          action
        end
        return false
      end
      return true
    end

    # Update the graphics
    def update_graphics
      # Update each animation
      if @entering
        update_entering_animation
      elsif @quiting
        update_quitting_animation
      else
        @buttons.each(&:update)
      end
    end

    # Overload the visible= to allow save to keep the curren background
    # @param value [Boolean]
    def visible=(value)
      if @in_save
        @buttons.each { |button| button.visible = value }
      else
        super(value)
      end
    end

    def fade_out(*)
      return unless @running

      animation = create_quitting_animation
      until animation.done?
        animation.update
        Graphics.update
      end
    end

    def fade_in(*)
      return if @entering
      Graphics.transition(8)

      @buttons[@index].selected = true
      animation = create_entering_animation
      until animation.done?
        animation.update
        Graphics.update
      end
    end

    private

    # Animation played during enter sequence
    def update_entering_animation
      @animation = create_entering_animation unless @animation
      @animation.update
      if @animation.done?
        @entering = false
        @__last_scene.spriteset.visible = false if @__last_scene.is_a?(Scene_Map)
        update_buttons
        @animation = nil
      end
    end

    def create_entering_animation
      ya = Yuki::Animation
      animation = ya.opacity_change(0.25, @background, 0, 255)
      @buttons.each do |button|
        animation.parallel_play(ya.move_discreet(0.25, button, button.x, button.y, button.x - ENTERING_ANIMATION_OFFSET, button.y))
      end
      animation.start
      return animation
    end

    # Animation played during the quit sequence
    def update_quitting_animation
      @animation = create_quitting_animation unless @animation
      @animation.update
      if @animation.done?
        @running = false
        @animation = nil
      end
    end

    def create_quitting_animation
      @__last_scene.spriteset.visible = true if @__last_scene.is_a?(Scene_Map) && !@animation
      ya = Yuki::Animation
      animation = ya.opacity_change(0.25, @background, 255, 0)
      @buttons.each do |button|
        button.selected = false
        animation.parallel_play(ya.move_discreet(0.25, button, button.x, button.y, button.x + ENTERING_ANIMATION_OFFSET, button.y))
      end
      animation.start
      return animation
    end

    # Create the conditional array telling which scene is enabled
    def init_conditions
      # @type [Array<Boolean>]
      @conditions = CONDITION_LIST.map(&:call)
    end

    # Init the image_indexes array
    def init_indexes
      # @type [Array<Integer>]
      @image_indexes = @conditions.collect.with_index { |condition, index| condition ? index : nil }
      @image_indexes.compact!
      push_quit_at_the_end
    end

    def push_quit_at_the_end
      quit_index = ACTION_LIST.index(:open_quit)
      return unless quit_index && @image_indexes.include?(quit_index)
      
      @image_indexes.delete(quit_index)
      @image_indexes << quit_index
    end

    # Create the background image (blur)
    def create_background
      add_disposable(@background = UI::BlurScreenshot.new(@viewport, @__last_scene))
      @background.opacity = 0
    end

    # Create the menu buttons
    def create_buttons
      # @type [Array<UI::PSDKMenuButtonBase>]
      @buttons = @image_indexes.map.with_index do |real_index, i|
        klass = BUTTON_OVERWRITES[real_index]&.call || UI::PSDKMenuButtonBase
        next klass.new(@viewport, real_index, i)
      end
    end

    # Update the menu button states
    def update_buttons
      @buttons.each_with_index { |button, index| button.selected = index == @index }
    end

    # Init the entering animation
    def init_entering
      @buttons.each { |button| button.move(ENTERING_ANIMATION_OFFSET, 0) }
    end

    # Perform the action to do at the current index
    def action
      play_decision_se
      send(ACTION_LIST[@image_indexes[@index]])
    end

    # Open the Dex UI
    def open_dex
      GamePlay.open_dex
    end

    # Open the Party_Menu UI
    def open_party
      GamePlay.open_party_menu do |scene|
        Yuki::FollowMe.update
        @background.update_snapshot
        if scene.call_skill_process || $game_temp.common_event_id != 0
          @call_skill_process = scene.call_skill_process
          @running = false
          Graphics.transition
        end
      end
    end

    # Open the Bag UI
    def open_bag
      GamePlay.open_bag
    end

    # Open the TCard UI
    def open_tcard
      GamePlay.open_player_information
    end

    # Open the Save UI
    def open_save
      @in_save = true
      call_scene(Save) do |scene|
        @running = false if scene.saved
        Graphics.transition
      end
      @in_save = false
    end

    # Open the Options UI
    def open_option
      GamePlay.open_options do |scene|
        if scene.modified_options.include?(:language)
          @running = false
          Graphics.transition
        end
      end
    end

    # Quit the scene
    def open_quit
      @quiting = true
    end

    class << self
      # Register a button in the UI
      # @param action [Symbol] method to call when the button is clicked
      # @param condition [Proc] block called to verify the condition
      def register_button(action, &condition)
        ACTION_LIST << action
        CONDITION_LIST << condition
      end

      # Register a button overwrite
      # @param index [Integer] index of the button
      # @param block [Proc, nil] proc called to get the overwrite button class to use
      def register_button_overwrite(index, &block)
        BUTTON_OVERWRITES[index] = block
      end

      # Clear all the thing that was previously registered so you can do it your way
      def clear_previous_registers
        ACTION_LIST.clear
        CONDITION_LIST.clear
        BUTTON_OVERWRITES.clear
      end
    end

    register_button(:open_dex) { $game_switches[Yuki::Sw::Pokedex] }
    register_button(:open_party) { $actors.any? }
    register_button(:open_bag) { !$bag.locked }
    register_button(:open_tcard) { true }
    register_button(:open_option) { true }
    register_button(:open_save) { !$game_system.save_disabled }
    register_button(:open_quit) { true }

    register_button_overwrite(2) { $trainer.playing_girl ? UI::GirlBagMenuButton : nil }
  end
end

GamePlay.menu_class = GamePlay::Menu
