#encoding: utf-8

#noyard
module GamePlay
  class Save < Base
    Windowskin="message"
    SaveFile = "Pokemon_Party"
    SaveDir = "Saves"
    BaseFilename = "#{SaveDir}/#{SaveFile}"
    Corrupted="Corrupted Save File"
    Unknown="Zone Inconnue"
    DispTime="%02d:%02d"
    def initialize(no_message=false)
      super(no_message)
      @save_window=Game_Window.new
      @save_window.x = 2
      @save_window.y = 2
      @save_window.z = 10001
      @save_window.width = 200
      @save_window.height = 108
      @save_window.windowskin = RPG::Cache.windowskin(Windowskin)
      @save_window.visible = false
#      @save_window.contents=Bitmap.new(172,80)
#      @save_window.contents.font.set_small_font
      @pokemon_party = nil
      Dir.mkdir(SaveDir) unless(File.exist?(SaveDir))
      unless(File.directory?(SaveDir))
        File.delete(SaveDir)
        Dir.mkdir(SaveDir)
      end
      @filename=BaseFilename
      @fileexist=File.exist?(@filename)
      build_window if(@fileexist)
    end

    def main_begin
      super
    end

    def main_process
      c=display_message(_get(26,15),1,_get(25,20),_get(25,21))
      if(c==0)
        save_game
        display_message(_parse(26,17, TRNAME[0] => $trainer.name))
      end
    end

    def build_window
      @pokemon_party = pokemon_party = $pokemon_party#Save.load
      (win = @save_window).visible = true
      #bmp = @save_window.contents
      width = 168#bmp.width
      if(pokemon_party)
        zone=pokemon_party.env.get_current_zone
        if(zone and $game_data_zone[zone])
          zone = $game_data_zone[zone].map_name
        else
          zone = Unknown
        end
        win.add_text(0,0,width,16,zone,0).load_color(3)

        win.add_text(0,16,width,16,_get(25,0),0) if(self.class != ::GamePlay::Save)
        win.add_text(0,32,width,16,_get(25,1),0)
        win.add_text(0,48,width,16,_get(25,3),0)
        win.add_text(0,64,width,16,_get(25,5),0)

        win.add_text(0,16,width,16,pokemon_party.trainer.name,2).
          load_color(pokemon_party.trainer.playing_girl ? 2 : 1)
        win.add_text(0,32,width,16,pokemon_party.trainer.badge_counter.to_s,2).load_color(1)
        win.add_text(0,48,width,16,pokemon_party.pokedex.pokemon_seen.to_s,2).load_color(1)
        time=pokemon_party.trainer.play_time
        hours=time/3600
        minutes=(time-3600*hours)/60
        win.add_text(0,64,width,16,sprintf(DispTime,hours,minutes),2).load_color(1)
      else
        win.add_text(0,0,width,16,Corrupted,1).load_color(2)
        @save_window.height = 44
      end
    end

    def save_game
      GamePlay::Save.save(@filename)
    end

    def dispose
      super
      @save_window.dispose
    end

    def self.save(filename = BaseFilename)
      $game_temp.message_proc = nil
      $game_temp.choice_proc = nil
      $game_temp.battle_proc = nil
      #>Préparations
      $trainer.update_play_time
      $trainer.current_version = PSDK_Version
      $trainer.game_version = Game_Version
      $game_map.begin_save
      save_data = "PKPRT"
      save_data << Marshal.dump($pokemon_party)
      #> Sauvegarde
      File.open(filename, "wb") { |f| f.write(save_data) }
      $game_map.end_save
    end

    def self.load
      filename = "#{SaveDir}/#{SaveFile}"
      return nil unless (File.exist?(filename))
      f=File.new(filename,"rb")
      #f.pos=5
      begin
        raise LoadError, "Fichier corrompu" if f.read(5) != "PKPRT"
        pokemon_party = Marshal.load(f)
        $pokemon_party = pokemon_party# unless $pokemon_party
        pokemon_party.load_parameters
      rescue Exception
        pokemon_party = nil
      end
      f.close
      return pokemon_party
    end
  end
end
