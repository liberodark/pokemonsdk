module GamePlay
  # Class that show the KeyBinding UI and allow to change it
  class KeyBinding < BaseCleanUpdate::FrameBalanced
    # List of keys use by the 3 modes
    KEYS = [%i[A RIGHT DOWN B]] * 3
    # List of mouse action in navigation mode
    MOUSE_ACTION_NAV = %i[action_a_nav action_a_nav action_down_nav action_b_nav]
    # List of mouse action in selection mode
    MOUSE_ACTION_SEL = %i[action_a_sel action_right_sel action_down_sel action_b_sel]
    # List of mouse action in blink mode
    MOUSE_ACTION_BLK = %i[action_b_blink action_b_blink action_b_blink action_b_blink]
    # List of keys to check when trying to overwrite an input
    KEYS_TO_CHECK = [:A, :B, :X, :Y, :UP, :DOWN, :RIGHT, :LEFT]
    # Create a new KeyBinding UI
    def initialize
      super
      @cool_down = 0
    end

    # Create the grahics of the KeyBinding scene
    def create_graphics
      create_viewport
      create_base_ui
      create_overlay
      create_ui
      Graphics.sort_z
    end

    # Update the graphics
    def update_graphics
      @base_ui.update_background_animation
      @ui.update_blink
    end

    # Update the inputs
    def update_inputs
      return @cool_down -= 1 if @cool_down > 0
      if @ui.key_index == -1
        update_navigation_input
      elsif @ui.blinking
        update_key_binding
      else
        update_key_selection
      end
    end

    # Update the mouse
    # @param _moved [Boolean] if the mouse moved
    def update_mouse(_moved)
      if @ui.blinking
        actions = MOUSE_ACTION_BLK
      elsif @ui.key_index >= 0
        actions = MOUSE_ACTION_SEL
      else
        actions = MOUSE_ACTION_NAV
      end
      update_mouse_ctrl_buttons(@base_ui.ctrl, actions, @base_ui.win_text_visible?)
    end

    private

    # Update the inputs during the naviation
    def update_navigation_input
      if Input.trigger?(:B)
        return action_b_nav
      elsif Input.trigger?(:A) || Input.trigger?(:RIGHT)
        action_a_nav
      elsif Input.trigger?(:LEFT)
        @ui.key_index = 4
      elsif Input.trigger?(:DOWN)
        action_down_nav
      elsif Input.trigger?(:UP)
        @ui.main_index -= 1
      end
    end

    # When the player presses A in navigation mode
    def action_a_nav
      @ui.key_index = 0
      @base_ui.mode = 1
    end

    # When the player presses DOWN in navigation mode
    def action_down_nav
      @ui.main_index += 1
    end

    # When the player presses B in navigation mode
    def action_b_nav
      KeyBinding.save_inputs
      return @running = false
    end

    # Update the key selection
    def update_key_selection
      if Input.trigger?(:B)
        action_b_sel
      elsif Input.trigger?(:A)
        return action_a_sel
      elsif Input.trigger?(:LEFT)
        @ui.key_index = (@ui.key_index - 1).clamp(0, 4)
      elsif Input.trigger?(:RIGHT)
        action_right_sel
      elsif Input.trigger?(:DOWN)
        action_down_sel
      elsif Input.trigger?(:UP)
        @ui.main_index -= 1
      end
    end

    # When the player presses A in selection mode
    def action_a_sel
      return display_message(ext_text(8998, 28)) if @ui.key_index == 4 && !Sf::Joystick.connected?(Input.main_joy)
      @ui.blinking = true
      @cool_down = 10
      @base_ui.mode = 2
      @base_ui.show_win_text(ext_text(8998, 29))
    end

    # When the player presses RIGHT in selection mode
    def action_right_sel
      return (@ui.key_index = (@ui.key_index + 1) % 5) if Mouse.released?(:LEFT)
      @ui.key_index = (@ui.key_index + 1).clamp(0, 4)
    end

    # When the player presses DOWN in selection mode
    def action_down_sel
      @ui.main_index += 1
    end

    # When the player presses B in selection mode
    def action_b_sel
      @ui.key_index = -1
      @base_ui.mode = 0
    end

    # Update the key detection during the UI blinking
    def update_key_binding
      if @ui.key_index < 4
        UI::KeyShortcut::KeyIndex.each do |key_value|
          return validate_key(key_value) if Input::Keyboard.press?(key_value)
        end
        UI::KeyShortcut::NUMPAD_KEY_INDEX.each do |key_value|
          return validate_key(key_value) if key_value >= 0 && Input::Keyboard.press?(key_value)
        end
      else
        unless Sf::Joystick.connected?(Input.main_joy)
          action_b_blink
          return display_message(ext_text(8998, 28))
        end
        return action_b_blink if Input::Keyboard.press?(Input::Keyboard::Escape)

        0.upto(Sf::Joystick.button_count(Input.main_joy)) do |key_value|
          if Sf::Joystick.press?(Input.main_joy, key_value)
            return validate_key((-key_value - 1) - 32 * Input.main_joy)
          end
        end
      end
    end

    # When the player presses "B" in blink mode
    def action_b_blink
      @base_ui.hide_win_text
      @ui.blinking = false
      @base_ui.mode = 1
    end

    # Validate the key change
    # @param key_value [Integer] the value of the key in Keyboard
    def validate_key(key_value)
      if key_value == Input::Keyboard::Escape
        ch = display_message_and_wait(ext_text(8998, 31), 1, ext_text(8998, 32), ext_text(8998, 33))
        return if ch == 0
      end
      key_value = Sf::Keyboard.delocalize(key_value) if key_value >= 0
      # Check if the key is already assigned to another option
      conflicting_key = find_already_assigned_key(key_value)
      # Check if any joystick button is pressed
      joystick_pressed = 0.upto(Sf::Joystick.button_count(Input.main_joy)).any? { |btn| Sf::Joystick.press?(Input.main_joy, btn) }
      # Message indicating key is already assigned
      unless conflicting_key.nil? || joystick_pressed
        $game_system.se_play($data_system.buzzer_se)
        return display_message(parse_text(65, 0, PFM::Text::NUMB[1] => conflicting_key.to_s))
      end
      Input::Keys[@ui.current_key][@ui.current_key_index] = key_value
      @ui.update
    ensure
      action_b_blink
    end

    # Check if the key is already assigned to another option
    # @param key_value [Integer] the value of the key in Keyboard
    def find_already_assigned_key(key_value)
      return Input::Keys.each.filter_map do |key, bound_keys|
        next if key == @ui.current_key || KEYS_TO_CHECK.none?(key)
        next unless bound_keys.include?(key_value)

        log_debug("Key '#{key_value}' is already assigned to '#{key}'")
        next key
      end.first
    end

    # Create the base ui
    def create_base_ui
      @base_ui = UI::GenericBaseMultiMode.new(@viewport, button_texts, KEYS)
    end

    # Create the overlay sprite
    def create_overlay
      @overlay = Sprite.new(@viewport).set_bitmap('key_binding/overlay_', :interface)
    end

    # Create the UI
    def create_ui
      @ui = UI::KeyBindingViewer.new(@viewport)
    end

    # Get the button text for the generic UI
    # @return [Array<Array<String>>]
    def button_texts
      return [
        [ext_text(8998, 22), ext_text(8998, 22), ext_text(9000, 112), ext_text(9000, 115)], # Nav
        [ext_text(8998, 26), ext_text(8998, 22), ext_text(9000, 112), ext_text(9000, 13)], # Sel
        [nil, nil, nil, ext_text(9000, 13)] # Blink
      ]
    end
  end
end
