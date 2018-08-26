#encoding: utf-8

#noyard
module GamePlay
  class Load < Save
    NewGame="Nouvelle partie"
    def initialize(delete_game = false)
      @viewport=Viewport.create(:main, 1)
      @viewport.color = Color.new(162,194,204)
      super(false)
      @save_window.x = 60
      @running=true
      @index=0
      @max_index=(@fileexist ? 2 : 1)
      @delete_game = @fileexist & delete_game
      if @delete_game
        $pokemon_party = PFM::Pokemon_Party.new(false, @pokemon_party.options.language)
        $pokemon_party.expand_global_var
        @save_window.visible = false
      end
      new_game_window
      Graphics.sort_z
    end

    def main
      curr_scene = $scene
      Graphics.transition
      check_up
      while(@running and curr_scene == $scene)
        Graphics.update
        update
      end
      ::Scheduler.start(:on_scene_switch, ::Scene_Title) unless @running
      dispose
    end

    def update
      return @message_window.update if @delete_game
      if(Input.trigger?(:DOWN))
        @index+=1
        @index=0 if @index>=@max_index
        refresh
      elsif(Input.trigger?(:UP))
        @index-=1
        @index=@max_index-1 if @index<0
        refresh
      elsif(Input.trigger?(:A))
        action
      elsif(Mouse.trigger?(:left))
        mouse_action
      elsif(Input.trigger?(:B) and $scene.class == ::Scene_Title)
        @running = false
      end
    end

    def new_game_window
      @new_window = Game_Window.new
      @new_window.x = 60
      @new_window.y = 112
      @new_window.z = 10001
      @new_window.width = 200
      @new_window.height = 32
      @new_window.add_text(0, 0, 200, 16, _ext(9000, 0))
      @new_window.opacity = 128
      @new_window.windowskin = RPG::Cache.windowskin(Windowskin)
      @new_window.visible = @save_window.visible
    end

    def action
      Graphics.freeze
      # @@save_index = @index
      if(@fileexist and @index==0)
        load_game
      else
        $pokemon_party = PFM::Pokemon_Party.new
        $pokemon_party.expand_global_var
        $game_system.se_play($data_system.cursor_se)
        $game_map.update
      end
      $trainer.redefine_var
      Yuki::FollowMe.set_battle_entry
      $pokemon_party.env.reset_zone
      $scene = Scene_Map.new
      Yuki::TJN.force_update_tone
      @running = false
    end

    def mouse_action
      if @save_window.visible
        if @save_window.simple_mouse_in?
          @index = 0
          action
        end
      end
      if @new_window.visible && @new_window.simple_mouse_in?
        @index = 1
        action
      end
    end

    def load_game
      $pokemon_party = @pokemon_party
      $pokemon_party.expand_global_var
      $game_system.se_play($data_system.cursor_se)
      $game_map.setup($game_map.map_id)
      $game_player.moveto($game_player.x, $game_player.y) #center
      $game_party.refresh
      $game_system.bgm_play($game_system.playing_bgm)
      $game_system.bgs_play($game_system.playing_bgs)
      $game_map.update
      #>Le système sauvegarde l'affichage de la fenêtre donc il faut régler le souci
      $game_temp.message_window_showing=false 
      #>On ajuste le marqueur de temps pour le temps de jeu
      $trainer.load_time
      $game_map.autoplay
    end

    def refresh
      if(@fileexist)
        @save_window.opacity = (@index != 0 ? 128 : 255)
      end
      @new_window.opacity = (@index != 1 ? 128 : 255)
    end

    def dispose
      super
      @new_window.dispose if @new_window
      @viewport.dispose
    end

    #===
    #> Vérification de l'intégrité de la sauvegarde
    #===
    def check_up
      #> Affichage des choix de suppression de partie
      if @delete_game
        #> Petit morceau de code permettant d'éviter que la messagewindow se saute
        while Input.press?(:B)
          Graphics.update
        end
        scene = $scene
        $scene = self
        message = _get(25, 18)
        oui = _get(25, 20)
        non = _get(25, 21)
        c = display_message(message, 1, non, oui) #> Supprimer ?
        if c == 1
          message = _get(25, 19)
          c = display_message(message, 1, non, oui) #> Vraiment ?
          if c == 1
            File.delete(@filename) #> Ok :)
            message = _get(25, 17)
            display_message(message)
          end
        end
        $scene = scene
        return @running = false
      end
      #> Affichage du choix de la langue
      unless @pokemon_party
        win1 = Game_Window.new
        win1.add_text(0,0,160,16,"Choose your language")
        win1.x = 80
        win1.y = 80
        win1.width = 160
        win1.height = 44
        win1.windowskin=RPG::Cache.windowskin(Windowskin)
        win2 = Window_Choice.new(160,["English","French","Spanish"])
        win2.x = 80
        win2.y = 128
        win2.z = win1.z = 200
        Graphics.sort_z
        loop do
          Graphics.update
          win2.update
          if win2.validated?
            break
          end
        end
        Graphics.freeze
        $pokemon_party = PFM::Pokemon_Party.new(false,["en","fr","es"][win2.index])
#        win2.contents.dispose
        win2.dispose
#        win1.contents.dispose
        win1.dispose
        $pokemon_party.expand_global_var
        $trainer.redefine_var
        $scene = Scene_Map.new
        Yuki::TJN.force_update_tone
        @running = false
      end
    end
  end
end
