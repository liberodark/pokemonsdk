# A module that helps the PSDK_DEBUG to perform some commands
module Debugger
  # Warp Error message
  WarpError = 'Aucune map de cet ID'
  # Name of the map to load to prevent warp error
  WarpMapName = 'Data/Map%03d.rxdata'
  module_function

  # Warp command
  # @param id [Integer] ID of the map to warp
  # @param x [Integer] X position
  # @param y [Integer] Y position
  # @author Nuri Yuri
  def warp(id, x = -1, y = -1)
    map = load_data(format(WarpMapName, id)) rescue nil
    return WarpError unless map

    if y < 0
      unless __find_maker_warp(id)
        __find_map_warp(map)
      end
    else
      $game_temp.player_new_x = x + ::Yuki::MapLinker.get_OffsetX
      $game_temp.player_new_y = y + ::Yuki::MapLinker.get_OffsetY
    end
    $game_temp.player_new_direction = 0
    $game_temp.player_new_map_id = id
    $game_temp.player_transferring = true
  end

  # Fight a specific trainer by its ID
  # @param id [Integer] ID of the trainer in Ruby Host
  # @param bgm [Array(String, Integer, Integer)] bgm description of the trainer battle
  # @param troop_id [Integer] ID of the RMXP Troop to use
  def battle_trainer(id, bgm = Interpreter::DEFAULT_TRAINER_BGM, troop_id = 3)
    original_battle_bgm = $game_system.battle_bgm
    $game_system.battle_bgm = RPG::AudioFile.new(*bgm)
    $game_variables[Yuki::Var::Trainer_Battle_ID] = id
    $game_temp.battle_abort = true
    $game_temp.battle_calling = true
    $game_temp.battle_troop_id = troop_id
    $game_temp.battle_can_escape = false
    $game_temp.battle_can_lose = false
    $game_temp.battle_proc = proc do |n|
      $game_system.battle_bgm = original_battle_bgm
    end
  end

  # Find the normal position where the player should warp in a specific map
  # @param id [Integer] id of the map
  # @return [Boolean] if a normal position has been found
  # @author Nuri Yuri
  def __find_maker_warp(id)
    each_data_zone do |data|
      if data.maps.include?(id)
        if data.warp.x && data.warp.y
          $game_temp.player_new_x = data.warp.x + ::Yuki::MapLinker.get_OffsetX
          $game_temp.player_new_y = data.warp.y + ::Yuki::MapLinker.get_OffsetY
          return true
        end
        break
      end
    end
    return false
  end

  # Find an alternative position where to warp
  # @param map [RPG::Map] the map data
  # @author Nuri Yuri
  def __find_map_warp(map)
    warp_x = cx = map.width / 2
    warp_y = cy = map.height / 2
    lowest_radius = ((cx * cy) * 2) ** 2
    map.events.each_value do |event|
      radius = (cx - event.x) ** 2 + (cy - event.y) ** 2
      if(radius < lowest_radius)
        if(__warp_command_found(event.pages))
          warp_x = event.x
          warp_y = event.y
          lowest_radius = radius
        end
      end
    end
    $game_temp.player_new_x = warp_x + ::Yuki::MapLinker.get_OffsetX
    $game_temp.player_new_y = warp_y + ::Yuki::MapLinker.get_OffsetY
  end

  # Detect a teleport command in the pages of an event
  # @param pages [Array<RPG::Event::Page>] the list of event page
  # @return [Boolean] if a command has been found
  # @author Nuri Yuri
  def __warp_command_found(pages)
    pages.each do |page|
      page.list.each do |command|
        return true if command.code == 201
      end
    end
    false
  end
end
