#encoding: utf-8

#noyard
# Description: Définition de la fenêtre de message des combats
class Scene_Battle
  class Window_Message < ::Window_Message
    WindowSkin = "M_4"
    PauseSkin = "Pause2"
    S_sl="\\"
    S_000="\000"
    S_001="\001"
    S_002="\x02"
    S_n="\n"
    S_cr="]"
    MAX_Wait=60
    attr_accessor :wait_input
    attr_accessor :blocking
    # Initialize the window Parameter
    def init_window
      @text_viewport = Viewport.create(0, 0, 320, LineHeight * LineCount)
      self.width = 320
      self.height = 48
      self.x = 0
      self.z = 10000
      @pause_x = @width - 16
      @pause_y = @height - 16
      self.window_builder = GameData::Windows::MessageHGSS
      self.windowskin = RPG::Cache.windowskin(WindowSkin)
      self.pauseskin = RPG::Cache.windowskin(PauseSkin)
      @wait_input = false
      @blocking = false
      @waiter = 0
    end
    # Show the Input Number Window
    # @return [Boolean] if the update function skips
    def update_input_number
      @waiter += 1 if @waiter < MAX_Wait
      return super
    end
    # Show the fade in during the update
    # @return [Boolean] if the update function skips
    def update_fade_in
      return false
    end
    # Skip the choice during update
    # @return [Boolean] if the function skips
    def update_choice_skip
      unless @wait_input
        terminate_message
        return true
      end
      return false
    end
    # Autoskip condition for the choice
    # @return [Boolean]
    def update_choice_auto_skip
      return (!$game_system.battle_interpreter.running? and @waiter>=MAX_Wait and !@blocking)
    end
    # Show the message text
    # @return [Boolean] if the update function skips
    def update_text_draw
      if $game_temp.message_text != nil
        @contents_showing = true
        $game_temp.message_window_showing = true
        reset_window
        text_dispose
        self.visible = true
        refresh
        #Graphics.frame_reset
        return true
      end
      return false
    end
    # Fade the window message out
    # @return [Boolean] if the update function skips
    def update_fade_out
      if self.visible
        $game_temp.message_window_showing = false
      end
      return false
    end
    # Generate the choice window
    def generate_choice_window
      super
      @waiter = 0
    end
    # Adjust the window position on screen
    def reset_window
      if($game_system.battle_interpreter.running?)
        case $game_system.message_position
        when 0 # En Haut
          self.y=2
        when 1 # Au centre
          self.y=90
        when 2 # En bas
          self.y=192
        end
      else
        self.y = 192
      end
    end
  end
end
