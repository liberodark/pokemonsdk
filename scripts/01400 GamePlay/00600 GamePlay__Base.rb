#encoding: utf-8

module GamePlay
  # The base class of every GamePlay scene interface
  #
  # Add some usefull functions like message display and scene switch
  # @author Nuri Yuri
  class Base
    # Default fade type used to switch between interfaces
    # @return [Symbol] :transition (for Graphics.freeze/transition), :fade_bk (for fade through black)
    DEFAULT_TRANSITION = :transition
    # Parameters of the transition
    # @return [Integer, Array] (usually the number of frame for the transition)
    DEFAULT_TRANSITION_PARAMETER = 16
    # Message the displays when a GamePlay scene has been initialized without message processing and try to display a message
    MESSAGE_ERROR = 'This interface has no MessageWindow, you cannot call display_message'
    ::PFM::Text.define_const(self)
    include Sprites
    include Input
    # The viewport in which the scene is shown
    # @return [Viewport, nil]
    attr_reader :viewport
    # The scene that called this scene (usefull when this scene needs to return to the last scene)
    # @return [#main]
    attr_reader :__last_scene
    # The message window
    # @return [Yuki::Message, nil]
    attr_reader :message_window
    # The process that is called when the call_scene method returns
    # @return [Proc, nil]
    attr_accessor :__result_process
    # If the current scene is still running
    # @return [Boolean]
    attr_accessor :running
    # Create a new GamePlay scene
    # @param no_message [Boolean] if the scene is created wihout the message management
    # @param message_z [Integer] the z superiority of the message
    # @param message_viewport_args [Array] if empty : [:main, message_z] will be used.
    def initialize(no_message = false, message_z = 10_001, *message_viewport_args)
      # Force the message window of the map to be closed
      $scene.window_message_close(true) if $scene.class == Scene_Map
      message_initialize(no_message, message_z, message_viewport_args)
      # Store the current scene
      @__last_scene = $scene
      _init_sprites
    end

    # Scene update process
    # @return [Boolean] if the scene should continue the update process or abort it (message/animation etc...)
    def update
      continue = true
      # We update the message window if there's a message window
      if @message_window
        @message_window.update
        return false if $game_temp.message_window_showing
      end
      return continue
    end

    # Dispose the scene graphics.
    # @note @viewport and @message_window will be disposed.
    def dispose
      @message_window&.dispose(with_viewport: true) unless @inherited_message_window || @message_window == false
      @viewport&.dispose
    end

    # The GamePlay entry point (Must not be overridden).
    def main
      # Store the last scene and store self in $scene
      @__last_scene = $scene if $scene != self
      $scene = self
      # Tell the interface is running
      @running = true
      # Main processing
      main_begin
      main_process
      main_end
      # Reset $scene unless it was already done
      $scene = @__last_scene if $scene == self
    end

    # Change the viewport visibility of the scene
    # @param value [Boolean]
    def visible=(value)
      @viewport.visible = value if @viewport
      @message_window.viewport.visible = value if @message_window
    end

    # Display a message with choice or not
    # @param message [String] the message to display
    # @param start [Integer] the start choice index (1..nb_choice)
    # @param choices [Array<String>] the list of choice options
    # @return [Integer, nil] the choice result
    def display_message(message, start = 1, *choices)
      raise ScriptError, MESSAGE_ERROR unless @message_window
      # message = @message_window.contents.multiline_calibrate(message)
      $game_temp.message_text = message
      processing_message = true
      $game_temp.message_proc = proc { processing_message = false }
      # Choice management
      choice = nil
      unless choices.empty?
        $game_temp.choice_max = choices.size
        $game_temp.choice_cancel_type = choices.size
        $game_temp.choice_proc = proc { |i| choice = i }
        $game_temp.choice_start = start
        $game_temp.choices = choices
      end
      edit_max = $game_temp.num_input_start > 0
      # Message update
      while processing_message
        Graphics.update
        @message_window.update
        @__display_message_proc&.call
        if edit_max && @message_window.input_number_window
          edit_max = false
          @message_window.input_number_window.max = $game_temp.num_input_start
        end
      end
      Graphics.update
      return choice
    end

    # Display a message with choice or not. This method will wait the message window to disappear
    # @param message [String] the message to display
    # @param start [Integer] the start choice index (1..nb_choice)
    # @param choices [Array<String>] the list of choice options
    # @return [Integer, nil] the choice result
    def display_message_and_wait(message, start = 1, *choices)
      choice = display_message(message, start, *choices)
      while $game_temp.message_window_showing
        Graphics.update
        @message_window.update
      end
      return choice
    end

    # Call an other scene
    # @param name [Class] the scene to call
    # @param args [Array] the parameter of the initialize method of the scene to call
    # @return [Boolean] if this scene can still run
    def call_scene(name, *args, &result_process)
      fade_out(@cfo_type || DEFAULT_TRANSITION, @cfo_param || DEFAULT_TRANSITION_PARAMETER)
      # Make the current scene invisible
      self.visible = false
      result_process ||= @__result_process
      @__result_process = nil
      scene = name.new(*args)
      scene.main
      # Call the result process if any
      result_process&.call(scene)
      # If the scene has changed we stop this one
      return @running = false if $scene != self || !@running
      self.visible = true
      fade_in(@cfi_type || DEFAULT_TRANSITION, @cfi_param || DEFAULT_TRANSITION_PARAMETER)
      return true
    end

    # Return to an other scene, create the scene if args.size > 0
    # @param name [Class] the scene to return to
    # @param args [Array] the parameter of the initialize method of the scene to call
    # @note This scene will stop running
    # @return [Boolean] if the scene has successfully returned to the desired scene
    def return_to_scene(name, *args)
      if args.empty?
        scene = self
        while scene.is_a?(Base)
          scene = scene.__last_scene
          break if scene == self
          next unless scene.class == name
          $scene = scene
          @running = false
          return true
        end
        return false
      end
      $scene = name.new(*args)
      @running = false
      return true
    end

    private

    # The main process at the begin of scene
    def main_begin
      fade_in(@mbf_type || DEFAULT_TRANSITION, @mbf_param || DEFAULT_TRANSITION_PARAMETER)
    end

    # The main process (block until scene stop running)
    def main_process
      while @running
        Graphics.update
        update
      end
    end

    # The main process at the end of the scene (when scene is not running anymore)
    def main_end
      fade_out(@mef_type || DEFAULT_TRANSITION, @mef_param || DEFAULT_TRANSITION_PARAMETER)
      dispose
    end

    # Initialize the window related interface of the UI
    # @param no_message [Boolean] if the scene is created wihout the message management
    # @param message_z [Integer] the z superiority of the message
    # @param message_viewport_args [Array] if empty : [:main, message_z] will be used.
    def message_initialize(no_message, message_z, message_viewport_args)
      if no_message.is_a?(::Yuki::Message)
        @message_window = no_message
        @inherited_message_window = true
      elsif no_message
        @message_window = false
      else
        # if $game_temp.in_battle
        #  @message_window = ::Scene_Battle::Window_Message.new
        #  @message_window.wait_input = true
        # else
        message_viewport_args = [:main, message_z] if message_viewport_args.empty?
        @message_window = message_class.new(Viewport.create(*message_viewport_args), self)
        # end
        @message_window.z = message_z
      end
    end

    # Perform an index change test and update the index (rotative)
    # @param varname [Symbol] name of the instance variable that plays the index
    # @param sub_key [Symbol] name of the key that substract 1 to the index
    # @param add_key [Symbol] name of the key that add 1 to the index
    # @param max [Integer] maximum value of the index
    # @param min [Integer] minmum value of the index
    def index_changed(varname, sub_key, add_key, max, min = 0)
      index = instance_variable_get(varname) - min
      mod = max - min + 1
      return false if mod <= 0 # Invalid value fix
      if Input.repeat?(sub_key)
        instance_variable_set(varname, (index - 1) % mod + min)
      elsif Input.repeat?(add_key)
        instance_variable_set(varname, (index + 1) % mod + min)
      end
      return instance_variable_get(varname) != (index + min)
    end

    # Perform an index change test and update the index (borned)
    # @param varname [Symbol] name of the instance variable that plays the index
    # @param sub_key [Symbol] name of the key that substract 1 to the index
    # @param add_key [Symbol] name of the key that add 1 to the index
    # @param max [Integer] maximum value of the index
    # @param min [Integer] minmum value of the index
    def index_changed!(varname, sub_key, add_key, max, min = 0)
      index = instance_variable_get(varname) - min
      mod = max - min + 1
      if Input.repeat?(sub_key) && index > 0
        instance_variable_set(varname, (index - 1) + min)
      elsif Input.repeat?(add_key) && index < mod && index != max
        instance_variable_set(varname, index + 1 + min)
      end
      return instance_variable_get(varname) != (index + min)
    end

    # Update the mouse CTRL button (button hub)
    # @param buttons [Array<UI::DexCTRLButton>] buttons to update
    # @param actions [Array<Symbol>] method to call if the button is clicked & released
    # @param only_test_return [Boolean] if we only test the return button
    # @param return_index [Integer] index of the return button
    def update_mouse_ctrl_buttons(buttons, actions, only_test_return = false, return_index = 3)
      if Mouse.trigger?(:left)
        buttons.each_with_index do |sp, i|
          next if only_test_return && i != return_index
          sp.set_press(sp.simple_mouse_in?)
        end
      elsif Mouse.released?(:left)
        buttons.each_with_index do |sp, i|
          next if only_test_return && i != return_index
          if sp.simple_mouse_in?
            send(actions[i])
            sp.set_press(false)
            break
          end
          sp.set_press(false)
        end
      end
    end

    # Return the message class used
    # @return [Class]
    def message_class
      Yuki::Message
    end

    # Process the fade out process (going through black)
    # @param type [Symbol] type of transition
    # @param parameters [Integer, Array] parameters of the transition
    def fade_out(type, parameters)
      case type
      when :transition
        Graphics.freeze
        Graphics.brightness = 255
      when :fade_bk
        (parameters - 1).downto(0) do |i|
          Graphics.brightness = i * 255 / parameters
          Graphics.update
        end
      end
    end

    # Process the fade in process
    # @param type [Symbol] type of transition
    # @param parameters [Integer, Array] parameters of the transition
    def fade_in(type, parameters)
      case type
      when :transition
        Graphics.brightness = 255
        Graphics.transition(*parameters)
      when :fade_bk
        1.upto(parameters) do |i|
          Graphics.brightness = i * 255 / parameters
          Graphics.update
        end
      end
    end

    # Define the transition info when the scene start
    # @param type [Symbol] type of transition
    # @param parameters [Integer, Array] parameters of the transition
    def define_main_begin_fade(type, parameters = nil)
      @mbf_type = type
      @mbf_param = parameters
    end

    # Define the transition info when the scene stops
    # @param type [Symbol] type of transition
    # @param parameters [Integer, Array] parameters of the transition
    def define_main_end_fade(type, parameters = nil)
      @mef_type = type
      @mef_param = parameters
    end

    # Define the transition info when we switch to the called scene
    # @param type [Symbol] type of transition
    # @param parameters [Integer, Array] parameters of the transition
    def define_call_scene_fade_out(type, parameters = nil)
      @cfo_type = type
      @cfo_param = parameters
    end

    # Define the transition info when we return from call_scene
    # @param type [Symbol] type of transition
    # @param parameters [Integer, Array] parameters of the transition
    def define_call_scene_fade_in(type, parameters = nil)
      @cfi_type = type
      @cfi_param = parameters
    end
  end
end
