#encoding: utf-8

module Scheduler
  add_proc(:on_warp_start, ::Scene_Map, "Enregistrement positions",1000,
    proc {
      @storage[:was_outside] = $game_switches[Yuki::Sw::Env_CanFly]
      @storage[:old_player_x] = $game_player.x - Yuki::MapLinker.current_OffsetX
      @storage[:old_player_y] = $game_player.y - Yuki::MapLinker.current_OffsetY
      @storage[:old_player_id] = $game_map.map_id
    }
  )
  add_proc(:on_warp_start, ::Scene_Map, "Calcul des positions des followers", 999,
    proc {
      @storage[:follower_arr] = arr = Array.new
      add_x = $game_temp.player_new_x - $game_player.x
      add_y = $game_temp.player_new_y - $game_player.y
      Yuki::FollowMe.each_follower do |i|
        arr<<(i.x + add_x)
        arr<<(i.y + add_y)
        arr<<i.direction
      end
    }
  )
  add_proc(:on_warp_process, ::Scene_Map, "Descendre du vélo s'il faut & reset force", 100,
    proc {
      if($env.get_current_zone_data.warp_disallowed)
        if($game_switches[::Yuki::Sw::EV_Bicycle])
          $game_system.map_interpreter.launch_common_event(11)
          $game_system.map_interpreter.update
        elsif($game_switches[::Yuki::Sw::EV_AccroBike])
          $game_system.map_interpreter.launch_common_event(33)
          $game_system.map_interpreter.update
        end
      end
      $game_switches[::Yuki::Sw::EV_Strength] = false
    }
  )
  add_proc(:on_warp_end, ::Scene_Map, "Reposition followers + update système", 1000,
    proc {
      if((@storage[:was_outside] and $game_switches[Yuki::Sw::Env_CanFly]) or $game_switches[Yuki::Sw::Env_FM_REP])
        $game_switches[Yuki::Sw::Env_FM_REP] = false
        Yuki::FollowMe.set_positions(*@storage[:follower_arr])
      else
        Yuki::FollowMe.reset_position unless $game_switches[Yuki::Sw::FM_NoReset]
        $game_switches[Yuki::Sw::FM_NoReset] = false
      end
      Yuki::FollowMe.update
      Yuki::Particles::update
      $wild_battle.reset
      $wild_battle.load_groups
    }
  )
  add_proc(:on_warp_end, ::Scene_Map, "Tunnel", 999,
    proc {
      if(@storage[:was_outside] and $game_switches[Yuki::Sw::Env_CanDig])
        $game_variables[Yuki::Var::E_Dig_ID] = @storage[:old_player_id]
        $game_variables[Yuki::Var::E_Dig_X] = @storage[:old_player_x]
        $game_variables[Yuki::Var::E_Dig_Y] = @storage[:old_player_y]
      end
    }
  )
  add_proc(:on_update, ::Scene_Map, "Ajout PSDK1", 1000,
    proc {
      Yuki::TJN.update
      Yuki::Particles.update
    }
  )
=begin
  add_proc(:on_update, ::Scene_Map, "Ajout Visual Debug", 1100,
    proc {
      if false#Input.trigger?(Input::F9) #£VisualDebug
        unless Yuki::VisualDebug.enabled? #£VisualDebug
          Yuki::VisualDebug.enable #£VisualDebug
        else #£VisualDebug
          Yuki::VisualDebug.disable #£VisualDebug
        end #£VisualDebug
      end #£VisualDebug
      Yuki::VisualDebug.update if Yuki::VisualDebug.enabled? #£VisualDebug
    }
  )
=end
  add_proc(:on_hour_update, ::Scene_Map, "Actualisation des groupes", 1000,
    proc {
      $wild_battle.reset
      $wild_battle.load_groups
    }
  )
  add_proc(:on_scene_switch, ::Scene_Title, "Correction des Pokémon", 1000,
    proc {
      if($scene.class != ::Scene_Title and $trainer.current_version.to_i <= 4864)
        puts("Conversion des Pokémon (skill_learnt / ribbons)")
        pokemon = nil
        block = proc do |pokemon|
          if pokemon
            pokemon.skill_learnt ||= []
            pokemon.ribbons ||= []
          end
        end
        $actors.each(&block)
        $storage.each_pokemon(&block)
        $storage.other_party(&block)
        $wild_battle.each_roaming_pokemon(&block)
      end
    }
  )
  add_proc(:on_scene_switch, ::Scene_Title, "Correction des quêtes", 1000,
    proc {
      if($scene.class != ::Scene_Title and $trainer.current_version.to_i <= 5635)
        puts("Conversion des quêtes")
        $quests.__convert
      end
    }
  )
=begin
  # Exemple de chargement de tileset automatique
  add_proc(:on_getting_tileset_name, :any, "Changement de tileset map 9", 1000,
    proc {
      if $game_temp.maplinker_map_id == 9
        $game_temp.tileset_name = "4G tileset_glace"
      end
    }
  )
=end
end
