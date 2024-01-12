# Module responsive of giving information about user Inputs
#
# The virtual keys of the Input module are : :A, :B, :X, :Y, :L, :R, :L2, :R2, :L3, :R3, :START, :SELECT, :HOME, :UP, :DOWN, :LEFT, :RIGHT
module Input
  # Alias for the Keyboard module
  Keyboard = Sf::Keyboard
  # Range giving dead zone of axis
  DEAD_ZONE = -20..20
  # Range outside of which a trigger is considered on an exis
  NON_TRIGGER_ZONE = -50..50
  # Sensitivity in order to take a trigger in account on joystick movement
  AXIS_SENSITIVITY = 10
  # Cooldown delta of Input.repeat?
  REPEAT_COOLDOWN = 0.25
  # Time between each signals of Input.repeat? after cooldown
  REPEAT_SPACE = 0.08
  # @type [Hash{ Symbol => Time }]
  @last_down_times = Hash.new { |hash, key| hash[key] = Graphics.current_time }
  # @type [Hash{ Symbol => Time }]
  @next_trigger_times = Hash.new { |hash, key| hash[key] = Graphics.current_time }
  # @type [Hash{ Symbol => Boolean }]
  @last_state = Hash.new { false }
  # @type [Hash{ Symbol => Boolean }]
  @current_state = Hash.new { false }
  # Main joy id
  @main_joy = 0
  # X axis
  @x_axis = Sf::Joystick::POV_X
  # Y axis
  @y_axis = Sf::Joystick::POV_Y
  # X Joystick Axis
  @x_joy_axis = Sf::Joystick::X
  # Y Joystick Axis
  @y_joy_axis = Sf::Joystick::Y
  # Last text user entered
  @last_text = nil
  s = Keyboard::Scancode
  # List of keys the input knows
  Keys = {
    A: [s::C, s::Space, s::Enter, s::NumpadEnter, -1],
    B: [s::X, s::Backspace, s::Escape, s::LShift, -2],
    X: [s::V, s::Menu, s::Numpad3, s::V, -3],
    Y: [s::B, s::Numpad1, s::RShift, s::B, -4],
    L: [s::F, s::Num1, s::Numpad7, s::F, -5],
    R: [s::G, s::Num3, s::Numpad9, s::G, -6],
    L2: [s::R, s::R, s::R, s::R, -7],
    R2: [s::T, s::T, s::T, s::T, -8],
    L3: [s::Num4, s::Num4, s::Y, s::F2, -9],
    R3: [s::Num5, s::Num5, s::U, s::F3, -10],
    START: [s::J, s::J, s::Insert, s::Insert, -8],
    SELECT: [s::H, s::H, s::Pause, s::Pause, -7],
    HOME: [s::Semicolon, s::Semicolon, s::Home, s::Home, 255],
    UP: [s::Up, s::W, s::Numpad8, s::Up, -13],
    DOWN: [s::Down, s::S, s::Numpad2, s::Down, -14],
    LEFT: [s::Left, s::A, s::Numpad4, s::Left, -15],
    RIGHT: [s::Right, s::D, s::Numpad6, s::Right, -16]
  }
  # List of key ALIAS
  ALIAS_KEYS = { up: :UP, down: :DOWN, left: :LEFT, right: :RIGHT, a: :A, b: :B, x: :X, y: :Y, start: :START, select: :SELECT }
  # List of Axis mapping (axis => key_neg, key_pos)
  AXIS_MAPPING = {
    Sf::Joystick::Z => %i[R2 L2]
  }
  # List of previous state of axis position
  @previous_axis_positions = Hash.new { |hash, key| hash[key] = Hash.new { 0 } }

  # List the id of joysticks connected
  @joysticks_connected = []

  class << self
    # Get the main joystick
    # @return [Integer]
    attr_accessor :main_joy
    # Get the X axis
    attr_accessor :x_axis
    # Get the Y axis
    attr_accessor :y_axis
    # Get the Joystick X axis
    attr_accessor :x_joy_axis
    # Get the Joystick Y axis
    attr_accessor :y_joy_axis

    # Get the 4 direction status
    # @return [Integer] 2 = down, 4 = left, 6 = right, 8 = up, 0 = none
    def dir4
      return 6 if press?(:RIGHT)
      return 4 if press?(:LEFT)
      return 2 if press?(:DOWN)
      return 8 if press?(:UP)

      return 0
    end

    # Get the 8 direction status
    # @return [Integer] see NumPad to know direction
    def dir8
      if press?(:DOWN)
        return 1 if press?(:LEFT)
        return 3 if press?(:RIGHT)

        return 2
      elsif press?(:UP)
        return 7 if press?(:LEFT)
        return 9 if press?(:RIGHT)

        return 8
      end

      return dir4
    end

    # Get the last entered text
    # @return [String, nil]
    def get_text
      return nil unless Graphics.focus?

      return @last_text
    end

    # Get the axis position of a joystick
    # @param id [Integer] ID of the joystick
    # @param axis [Integer] axis
    # @return [Integer]
    def joy_axis_position(id, axis)
      Sf::Joystick.axis_position(id, axis)
    end

    # Tell if a key is pressed
    # @param key [Symbol] name of the key
    # @return [Boolean]
    def press?(key)
      return false unless Graphics.focus?

      key = ALIAS_KEYS[key] || key unless Keys[key]
      return @current_state[key]
    end

    # Tell if a key was triggered
    # @param key [Symbol] name of the key
    # @return [Boolean]
    def trigger?(key)
      return false unless Graphics.focus?

      key = ALIAS_KEYS[key] || key unless Keys[key]
      return @current_state[key] && !@last_state[key]
    end

    # Tell if a key was released
    # @param key [Symbol] name of the key
    # @return [Boolean]
    def released?(key)
      return false unless Graphics.focus?

      key = ALIAS_KEYS[key] || key unless Keys[key]
      return @last_state[key] && !@current_state[key]
    end

    # Tell if a key is repeated (0.25s then each 0.08s)
    # @param key [Symbol] name of the key
    # @return [Boolean]
    def repeat?(key)
      return false unless Graphics.focus?

      key = ALIAS_KEYS[key] || key unless Keys[key]
      return false unless @current_state[key]

      # Note: we cannot compare with Graphics.current_time because its updated after the events
      return true if trigger?(key)

      delta = Graphics.current_time - @last_down_times[key]
      return false if delta < REPEAT_COOLDOWN
      return false if @last_down_times[key] > Graphics.current_time

      return true
    end

    # Swap the states (each time input gets updated)
    def swap_states
      @last_state.merge!(@current_state)

      @last_down_times.each do |key, value|
        next unless repeat?(key)

        delta = Graphics.current_time - value
        @last_down_times[key] = Graphics.current_time - (REPEAT_COOLDOWN - REPEAT_SPACE) if delta >= REPEAT_COOLDOWN
      end
      @last_text = nil
    end

    # Register all events in the window
    # @param window [LiteRGSS::DisplayWindow]
    def register_events(window)
      window.on_text_entered = proc { |text| on_text_entered(text) }
      window.on_key_pressed = proc { |_, scan, alt| on_key_down(scan, alt) }
      window.on_key_released = proc { |_, scan| on_key_up(scan) }
      window.on_joystick_button_pressed = proc { |id, button| on_joystick_button_pressed(id, button) }
      window.on_joystick_button_released = proc { |id, button| on_joystick_button_released(id, button) }
      window.on_joystick_connected = proc { |id| on_joystick_connected(id) }
      window.on_joystick_disconnected = proc { |id| on_joystick_disconnected(id) }
      window.on_joystick_moved = proc { |id, axis, position| on_axis_moved(id, axis, position) }
    end

    private

    # Set the last entered text
    # @param text [String]
    def on_text_entered(text)
      @last_text = text
    end

    # Set a key up
    # @param key [Integer]
    # @param alt [Boolean] if the alt key is pressed
    def on_key_down(key, alt = false)
      return Graphics.swap_fullscreen if alt && key == Sf::Keyboard::Scancode::Enter && Graphics.fullscreen_toggle_enabled

      vkey, = Keys.find { |_, v| v.include?(key) }
      return unless vkey

      @current_state[vkey] = true
      @last_down_times[vkey] = Graphics.current_time unless @last_state[vkey]
    end

    # Set a key down
    # @param key [Integer]
    def on_key_up(key)
      vkey, = Keys.find { |_, v| v.include?(key) }
      return unless vkey

      @current_state[vkey] = false
    end

    # Trigger a key depending on the joystick axis movement
    # @param id [Integer] id of the joystick
    # @param axis [Integer] axis
    # @param position [Integer] new position
    def on_axis_moved(id, axis, position)
      on_joystick_connected(id)
      return if id != main_joy

      last_position = @previous_axis_positions[id][axis]
      return if (position - last_position).abs <= AXIS_SENSITIVITY

      @previous_axis_positions[id][axis] = position
      if id == main_joy
        return on_axis_x(position) if axis == x_axis || axis == x_joy_axis
        return on_axis_y(position) if axis == y_axis
        return on_axis_joy_y(position) if axis == y_joy_axis
      end

      return unless (mapping = AXIS_MAPPING[axis])

      if DEAD_ZONE.include?(position)
        @current_state[mapping.first] = @current_state[mapping.last] = false
        return
      elsif position.positive?
        @current_state[e = mapping.last] = true
        @last_down_times[e] = Graphics.current_time unless @last_state[e]
        @current_state[mapping.first] = false
      else
        @current_state[e = mapping.first] = true
        @last_down_times[e] = Graphics.current_time unless @last_state[e]
        @current_state[mapping.last] = false
      end
    end

    # Trigger a RIGHT or LEFT thing depending on x axis position
    # @param position [Integer] new position
    def on_axis_x(position)
      if NON_TRIGGER_ZONE.include?(position)
        @current_state[:LEFT] = @current_state[:RIGHT] = false
        return
      elsif position.positive?
        @current_state[:RIGHT] = true
        @last_down_times[:RIGHT] = Graphics.current_time unless @last_state[:RIGHT]
        @current_state[:LEFT] = false
      else
        @current_state[:LEFT] = true
        @last_down_times[:LEFT] = Graphics.current_time unless @last_state[:LEFT]
        @current_state[:RIGHT] = false
      end
    end

    # Trigger a UP or DOWN thing depending on y axis position (D-Pad)
    # @param position [Integer] new position
    def on_axis_y(position)
      if NON_TRIGGER_ZONE.include?(position)
        @current_state[:UP] = @current_state[:DOWN] = false
        return
      elsif position.positive?
        @current_state[:UP] = true
        @last_down_times[:UP] = Graphics.current_time unless @last_state[:UP]
        @current_state[:DOWN] = false
      else
        @current_state[:DOWN] = true
        @last_down_times[:DOWN] = Graphics.current_time unless @last_state[:DOWN]
        @current_state[:UP] = false
      end
    end

    # Trigger a UP or DOWN thing depending on y axis position (Joystick)
    # @param position [Integer] new position
    def on_axis_joy_y(position)
      if NON_TRIGGER_ZONE.include?(position)
        @current_state[:UP] = @current_state[:DOWN] = false
        return
      elsif position.positive?
        @current_state[:DOWN] = true
        @last_down_times[:DOWN] = Graphics.current_time unless @last_state[:DOWN]
        @current_state[:UP] = false
      else
        @current_state[:UP] = true
        @last_down_times[:UP] = Graphics.current_time unless @last_state[:UP]
        @current_state[:DOWN] = false
      end
    end

    # Add the joystick to the list of connected joysticks and the new joystick connected becomes the main joystick
    # @param id [Integer] id of the joystick
    def on_joystick_connected(id)
      return if @joysticks_connected.include?(id)

      @joysticks_connected << id
      @main_joy = id
    end

    # Remove the joystick to the list of connected joysticks and change the main joystick if other joystick are connected
    # @param id [Integer] id of the joystick
    def on_joystick_disconnected(id)
      @joysticks_connected.delete(id)
      @main_joy = @joysticks_connected.empty? ? 0 : @joysticks_connected.last
    end

    # Set a key down if the button pressed comes of main joystick
    # @param id [Integer] id of the joystick
    # @param button [Integer]
    def on_joystick_button_pressed(id, button)
      on_key_down(- button - 1) if id == main_joy
    end

    # Set a key up if the button released comes of main joystick
    # @param id [Integer] id of the joystick
    # @param button [Integer]
    def on_joystick_button_released(id, button)
      on_key_up(- button - 1) if id == main_joy
    end
  end
end
