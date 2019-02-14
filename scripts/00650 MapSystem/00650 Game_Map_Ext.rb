class Game_Map
  # If an event has been erased (helps removing it)
  # @return [Boolean]
  attr_accessor :event_erased

  # Retreive the ID of the SystemTag on a specific tile
  # @param x [Integer] x position of the tile
  # @param y [Integer] y position of the tile
  # @return [Integer]
  # @author Nuri Yuri
  def system_tag(x, y)
    if @map_id != 0
      tiles = self.data
      2.downto(0) do |i|
        tile_id = tiles[x, y, i]
        return 0 unless tile_id
        tag_id = @system_tags[tile_id]
        return tag_id if tag_id and tag_id > 0
      end
    end
    return 0
  end

  # Check if a specific SystemTag is present on a specific tile
  # @param x [Integer] x position of the tile
  # @param y [Integer] y position of the tile
  # @param tag [Integer] ID of the SystemTag
  # @return [Boolean]
  # @author Nuri Yuri
  def system_tag_here?(x, y, tag)
    if @map_id != 0
      tiles = self.data
      2.downto(0) do |i|
        tile_id = tiles[x, y, i]
        next unless tile_id
        return true if @system_tags[tile_id] == tag
      end
    end
    return false
  end

  # Loads the SystemTags of the map
  # @author Nuri Yuri
  def load_systemtags
    @system_tags = $data_system_tags[@map.tileset_id]
    unless @system_tags
      print "Les tags du tileset #{@map.tileset_id} n'existent pas. 
PSDK va entrer en configuration des SystemTags merci de les sauvegarder"
      Yuki::SystemTagEditor.start
      @system_tags = $data_system_tags[@map.tileset_id]
    end
  end

  # Retreive the id of a specific tile
  # @param x [Integer] x position of the tile
  # @param y [Integer] y position of the tile
  # @return [Integer] id of the tile
  # @author Nuri Yuri
  def get_tile(x, y)
    2.downto(0) do |i|
      tile = data[x, y, i]
      return tile if tile and tile > 0
    end
    return 0
  end

  # Check if the player can jump a case with the acro bike
  # @param x [Integer] x position of the tile
  # @param y [Integer] y position of the tile
  # @param d [Integer] the direction of the player
  # @return [Boolean]
  # @author Nuri Yuri
  def jump_passable?(x, y, d)
    z = $game_player.z
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    sys_tag = system_tag(new_x, new_y)
    systemtags = GameData::SystemTags
    if z <= 1 and (system_tag(x, y) == systemtags::AcroBike or sys_tag == systemtags::AcroBike)
      return true
    elsif z > 1 and (Game_Player::AccroTag.include?(sys_tag) or sys_tag == systemtags::BridgeUD)
      return true
    end
    case d
    when 2
      new_d = 8
    when 6
      new_d = 4
    when 4
      new_d = 6
    else
      new_d = 2
    end
    # 与えられた座標がマップ外の場合
    unless valid?(x, y) and valid?(new_x, new_y)
      # 通行不可
      return false
    end
    # 方向 (0,2,4,6,8,10) から 障害物ビット (0,1,2,4,8,0) に変換
    bit = (1 << (d / 2 - 1)) & 0x0f
    bit2 = (1 << (new_d / 2 - 1)) & 0x0f
    # レイヤーの上から順に調べるループ
    2.downto(0) do |i|
      # タイル ID を取得
      tile_id = data[x, y, i]
      tile_id2 = data[new_x, new_y, i]
      if @passages[tile_id] & bit != 0 or @passages[tile_id2] & bit2 != 0
        # 通行不可
        return false
      elsif @priorities[tile_id] == 0
        # 通行可
        return true
      end
    end
    # 通行可
    return true
  end

  # List of variable to remove in order to keep the map data safe
  IVAR_TO_REMOVE_FROM_SAVE_FILE = %i[@map @tileset_name @autotile_names @panorama_name @panorama_hue @fog_name @fog_hue @fog_opacity @fog_blend_type @fog_zoom @fog_sx @fog_sy @battleback_name @passages @priorities @terrain_tags @events @common_events @system_tags]

  # Method that prevent non wanted data save of the Game_Map object
  # @author Nuri Yuri
  def begin_save
    save_follower
    arr = []
    IVAR_TO_REMOVE_FROM_SAVE_FILE.each do |ivar_name|
      arr << instance_variable_get(ivar_name)
      remove_instance_variable(ivar_name)
    end
    arr << $game_player.follower
    $game_player.instance_variable_set(:@follower, nil)
    $TMP_MAP_DATA = arr
  end

  # Method that end the save state of the Game_Map object
  # @author Nuri Yuri
  def end_save
    arr = $TMP_MAP_DATA
    IVAR_TO_REMOVE_FROM_SAVE_FILE.each_with_index do |ivar_name, index|
      instance_variable_set(ivar_name, arr[index])
    end
    $game_player.instance_variable_set(:@follower, arr.last)
  end

  private

  # Method that save the Follower Event of the player
  def save_follower
    return unless $game_player.follower.is_a?(Game_Event)
    @next_setup_followers = []
    follower = $game_player
    while (follower = follower.follower).is_a?(Game_Event)
      @next_setup_followers << follower.id
    end
  end

  # Method that load the follower Event of the player when the map is loaded
  def load_follower
    $game_player.reset_follower
    x = $game_player.x
    y = $game_player.y
    @next_setup_followers.each do |id|
      next unless (event = @events[id])
      event.moveto(x, y)
      $game_player.set_follower(event)
    end
    remove_instance_variable(:@next_setup_followers)
  end
end
