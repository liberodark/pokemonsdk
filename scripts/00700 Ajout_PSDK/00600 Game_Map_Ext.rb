#encoding: utf-8

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
  # Method that prevent non wanted data save of the Game_Map object (Project dump from save)
  # @author Nuri Yuri
  def begin_save
    $TMP_MAP_DATA = [@map,
    @tileset_name,
    @autotile_names,
    @panorama_name,
    @panorama_hue,
    @fog_name,
    @fog_hue,
    @fog_opacity,
    @fog_blend_type,
    @fog_zoom,
    @fog_sx,
    @fog_sy,
    @battleback_name,
    @passages,
    @priorities,
    @terrain_tags,
    @events]
    @map=nil
    @tileset_name=nil
    @autotile_names=nil
    @panorama_name=nil
    @panorama_hue=nil
    @fog_name=nil
    @fog_hue=nil
    @fog_opacity=nil
    @fog_blend_type=nil
    @fog_zoom=nil
    @fog_sx=nil
    @fog_sy=nil
    @battleback_name=nil
    @passages=nil
    @priorities=nil
    @terrain_tags=nil
    @events=nil
  end
  # Method that end the save state of the Game_Map object (Project dump from save)
  # @author Nuri Yuri
  def end_save
    a = $TMP_MAP_DATA
    @map=a[0]
    @tileset_name=a[1]
    @autotile_names=a[2]
    @panorama_name=a[3]
    @panorama_hue=a[4]
    @fog_name=a[5]
    @fog_hue=a[6]
    @fog_opacity=a[7]
    @fog_blend_type=a[8]
    @fog_zoom=a[9]
    @fog_sx=a[10]
    @fog_sy=a[11]
    @battleback_name=a[12]
    @passages=a[13]
    @priorities=a[14]
    @terrain_tags=a[15]
    @events=a[16]
  end
end
