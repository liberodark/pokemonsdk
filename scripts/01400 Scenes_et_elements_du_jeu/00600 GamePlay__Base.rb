#encoding: utf-8

module GamePlay
  # The base class of every GamePlay scene interface
  # 
  # Add some usefull functions like message display and scene switch
  # @author Nuri Yuri
  class Base
    # Message the displays when a GamePlay scene has been initialized without message processing and try to display a message
    MessageError = "This interface has no MessageWindow, you cannot call display_message"
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
    # @return [Window_Message, nil]
    attr_reader :message_window
    # The process that is called when the call_scene method returns
    # @return [Proc, nil]
    attr_accessor :__result_process
    # If the current scene is still running
    # @return [Boolean]
    attr_accessor :running
    # Create a new GamePlay scene
    # @param no_message [Boolean] if the scene is created wihout the message management
    # @param z [Integer] the z superiority of the message
    def initialize(no_message = false, z = 10001)
      if(no_message.class == ::Window_Message)
        @message_window = no_message
        @inherited_message_window = true
      elsif(no_message)
        @message_window = false
      else
#        if $game_temp.in_battle
#          @message_window = ::Scene_Battle::Window_Message.new
#          @message_window.wait_input = true
#        else
          @message_window = ::Window_Message.new
#        end
        @message_window.z = z
      end
      _init_sprites
    end
    # Scene update process
    # @return [Boolean] if the scene should continue the update process or abort it (message/animation etc...)
    def update
      #> S'il y a des animations de sprite
      continue = true #< Ajouter ici le process de certaines animations
      #> Si l'interface a une fenêtre de message, on met à jour
      if @message_window
        @message_window.update
        return false if $game_temp.message_window_showing
      end
      return continue
    end
    # Dispose the scene sprites.
    def dispose
      @message_window.dispose unless @inherited_message_window || !@message_window
      dispose_sprites
    end
    # The GamePlay entry point (Must not be overridden).
    def main
      #> Sauvegarde de la scène précédent
      @__last_scene = $scene
      $scene = self
      #> Variable indiquant que la scène est en fonctionnement
      @running = true
      #> Process principal
      main_begin
      main_process
      main_end
      #> Récupération de la scène précédente sauf avis contraire
      $scene = @__last_scene if $scene == self
    end
    # The main process at the begin of scene
    def main_begin
      Graphics.transition
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
      Graphics.freeze
      dispose
    end
    # Change the viewport visibility of the scene
    # @param v [Boolean]
    def visible=(v)
      @viewport.visible = v if @viewport
    end
    # Call an other scene
    # @param name [Class] the scene to call
    # @param args [Array] the parameter of the initialize method of the scene to call
    # @return [Boolean] if this scene can still run
    def call_scene(name, *args)
      Graphics.freeze
      #> Mise automatique du viewport en non visible (@__last_scene.viewport.visible = true pour rerendre visible)
      self.visible = false
      result_process = @__result_process
      @__result_process = nil
      scene = name.new(*args)
      scene.main
      #> Traitement du résultat si il est défini
      result_process.call(scene) if result_process
      #> Si la scène est différente, on arrête le processus de celle-ci
      return @running = false if $scene != self or !@running
      self.visible = true
      Graphics.transition
      return true
    end
    # Return to an other scene, create the scene if not found or args.size > 0
    # @param name [Class] the scene to return to
    # @param args [Array] the parameter of the initialize method of the scene to call
    # @note This scene will stop running
    # @return [Boolean] if the scene has successfully returned to the desired scene
    def return_to_scene(name, *args)
      if(args.size == 0)
        scene = self
        while scene.is_a?(Base)
          scene = scene.__last_scene
          if(scene.class == name)
            $scene = scene
            @running = false
            return true
          end
        end
        return false
      end
      $scene = name.new(*args)
      @running = false
      return true
    end
    # Display a message with choice or not
    # @param message [String] the message to display
    # @param start [Integer] the start choice index (1..nb_choice)
    # @param choices [Array<String>] the list of choice options
    # @return [Integer, nil] the choice result
    def display_message(message, start=1, *choices)
      raise ScriptError, MessageError unless @message_window
      #message = @message_window.contents.multiline_calibrate(message)
      $game_temp.message_text = message
      processing_message = true
      $game_temp.message_proc = proc { processing_message = false }
      #> Intégration du choix
      choice = nil
      if(choices.size>0)
        $game_temp.choice_max = choices.size
        $game_temp.choice_cancel_type = choices.size
        $game_temp.choice_proc = proc { |i| choice = i }
        $game_temp.choice_start = start
        $game_temp.choices = choices
      end
      edit_max = $game_temp.num_input_start > 0
      #> Mise à jour du message
      while processing_message
        Graphics.update
        @message_window.update
        @__display_message_proc.call if @__display_message_proc
        if(edit_max and @message_window.input_number_window)
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
    def display_message_and_wait(message, start=1, *choices)
      choice = display_message(message, start, *choices)
      while $game_temp.message_window_showing
        Graphics.update
        @message_window.update
      end
      return choice
    end
    # Perform an index change test and update the index (rotative)
    # @param varname [Symbol] name of the instance variable that plays the index
    # @param sub_key [Symbol] name of the key that substract 1 to the index
    # @param add_key [Symbol] name of the key that add 1 to the index
    # @param max [Integer] maximum value of the index
    # @param min [Integer] minmum value of the index
    def index_changed(varname, sub_key, add_key, max, min = 0)
      index = self.instance_variable_get(varname) - min
      mod = max - min + 1
      return false if mod <= 0 # Invalid value fix
      if Input.repeat?(sub_key)
        self.instance_variable_set(varname, (index - 1) % mod + min)
      elsif Input.repeat?(add_key)
        self.instance_variable_set(varname, (index + 1) % mod + min)
      end
      return self.instance_variable_get(varname) != (index + min)
    end
    # Perform an index change test and update the index (borned)
    # @param varname [Symbol] name of the instance variable that plays the index
    # @param sub_key [Symbol] name of the key that substract 1 to the index
    # @param add_key [Symbol] name of the key that add 1 to the index
    # @param max [Integer] maximum value of the index
    # @param min [Integer] minmum value of the index
    def index_changed!(varname, sub_key, add_key, max, min = 0)
      index = self.instance_variable_get(varname) - min
      mod = max - min + 1
      if Input.repeat?(sub_key) and index > 0
        self.instance_variable_set(varname, (index - 1) + min)
      elsif Input.repeat?(add_key) and index < mod
        self.instance_variable_set(varname, index + 1 + min)
      end
      return self.instance_variable_get(varname) != (index + min)
    end
  end
end
