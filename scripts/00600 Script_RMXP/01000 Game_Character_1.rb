#encoding: utf-8

# Class that describe and manipulate a Character (Player/Events)
class Game_Character
  include GameData::SystemTags
  # Id of the event in the map
  # @return [Integer]
  attr_reader   :id
  attr_accessor   :x                        # マップ X 座標 (論理座標)
  attr_accessor   :y                        # マップ Y 座標 (論理座標)
  attr_accessor   :z                        # Position z du chara
  attr_reader   :real_x                   # マップ X 座標 (実座標 * 128)
  attr_reader   :real_y                   # マップ Y 座標 (実座標 * 128)
  attr_reader   :tile_id                  # タイル ID  (0 なら無効)
  attr_accessor   :character_name           # キャラクター ファイル名
  attr_accessor   :character_hue            # キャラクター 色相
  attr_accessor   :opacity                  # 不透明度
  attr_reader   :blend_type               # 合成方法
  attr_accessor   :direction                # 向き
  attr_reader   :pattern                  # パターン
  attr_reader   :move_route_forcing       # 移動ルート強制フラグ
  attr_accessor  :through                  # すり抜け
  attr_accessor :animation_id             # アニメーション ID
  attr_accessor :transparent              # 透明状態
  attr_accessor :move_speed # move_speed
  attr_accessor :step_anime # if the character is animated while staying
  attr_accessor :in_swamp # if the character is in a swamp tile
  attr_accessor :is_pokemon # if the character is a pokemon
  # Default initializer
  def initialize
    @id = 0
    @x = 0
    @y = 0
    @z = 1
    @real_x = 0
    @real_y = 0
    @tile_id = 0
    @character_name = nil.to_s
    @character_hue = 0
    @opacity = 255
    @blend_type = 0
    @direction = 2
    @pattern = 0
    @move_route_forcing = false
    @through = false
    @animation_id = 0
    @transparent = false
    @original_direction = 2
    @original_pattern = 0
    @move_type = 0
    @move_speed = 4
    @move_frequency = 6
    @move_route = nil
    @move_route_index = 0
    @original_move_route = nil
    @original_move_route_index = 0
    @walk_anime = true
    @step_anime = false
    @direction_fix = false
    @always_on_top = false
    @anime_count = 0
    @stop_count = 0
    @jump_count = 0
    @jump_peak = 0
    @wait_count = 0
    @locked = false
    @prelock_direction = 0
    @surfing = false #Variable indiquant si le chara est sur l'eau
    @sliding = false #Variable indiquant si le chara slide
    @pattern_state = false #Indicateur de la direction du pattern
  end
  # is the character moving ?
  # @return [Boolean]
  def moving?
    return (@real_x != @x * 128 or @real_y != @y * 128)
  end
  # is the character jumping ?
  # @return [Boolean]
  def jumping?
    return @jump_count > 0
  end
  # Adjust the character position
  def straighten
    # 移動時アニメまたは停止時アニメが ON の場合
    if @walk_anime or @step_anime
      # パターンを 0 に設定
      @pattern = 0
      @pattern_state = false
    end
    # アニメカウントをクリア
    @anime_count = 0
    # ロック前の向きをクリア
    @prelock_direction = 0
  end
  # Force the character to adopt a move route and save the original one
  def force_move_route(move_route)
    # オリジナルの移動ルートを保存
    if @original_move_route == nil
      @original_move_route = @move_route
      @original_move_route_index = @move_route_index
    end
    # 移動ルートを変更
    @move_route = move_route
    @move_route_index = 0
    # 移動ルート強制フラグをセット
    @move_route_forcing = true
    # ロック前の向きをクリア
    @prelock_direction = 0
    # ウェイトカウントをクリア
    @wait_count = 0
    # カスタム移動
    move_type_custom
  end
  # SystemTags that trigger Surfing
  SurfTag = [TPond, TSea]
  # SystemTags that does not trigger leaving water
  SurfLTag = SurfTag + [BridgeUD, BridgeRL, RapidsL, RapidsR, RapidsU, RapidsD, AcroBikeRL, AcroBikeUD, WaterFall]
  # is the tile in front of the character passable ?
  # @param x [Integer] x position on the Map
  # @param y [Integer] y position on the Map
  # @param d [Integer] direction : 2, 4, 6, 8, 0. 0 = current position
  # @param skip_event [Boolean] if the function does not check events
  # @return [Boolean] if the front/current tile is passable
  def passable?(x, y, d, skip_event = false)
    # 新しい座標を求める
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    game_map = $game_map
    # 座標がマップ外の場合
    unless game_map.valid?(new_x, new_y)
      # 通行不可
      return false
    end
    # すり抜け ON の場合
    if @through and !@sliding
      # 通行可
      return true
    end

    if @sliding and @through and $game_switches[::Yuki::Sw::ThroughEvent]
      # 通行可
      return true
    end

    z = @z
    #> Ponts
    if z > 1 and bridge = @__bridge
      return false unless game_map.system_tag_here?(new_x, new_y, bridge[0]) or 
          game_map.system_tag_here?(new_x, new_y, bridge[1]) or
          game_map.system_tag_here?(x, y, bridge[1])
    end
    sys_tag = game_map.system_tag(new_x,new_y)
    #> Sécurité pour les ponts
    no_game_map = false
    if z > 1
      case d
      when 2, 8
        no_game_map = true if sys_tag == BridgeUD
      when 4, 6
        no_game_map = true if sys_tag == BridgeRL
      end
    end
    unless @__bridge or no_game_map
      # 移動元のタイルから指定方向に出られない場合
      unless game_map.passable?(x, y, d, self)
        # 通行不可
        return false
      end
      # 移動先のタイルに指定方向から入れない場合
      unless game_map.passable?(new_x, new_y, 10 - d)
        # 通行不可
        return false
      end
    end
    #>Surf
    if(!@surfing and (SurfTag.include?(sys_tag)))
      if self == $game_player and !$game_switches[Yuki::Sw::NoSurfContact]
        v = self.front_tile_event
        return false if v and !v.through and v.character_name.size>0
        $game_temp.common_event_id = 9 #>Appeler l'évent de surf
      end
      return false
    elsif(@surfing and !SurfLTag.include?(sys_tag))
      if self==$game_player #and !$game_switches[Yuki::Sw::NoSurfContact]
        v = self.front_tile_event
        return false if v and !v.through and v.character_name.size>0
        @surfing = false
        $game_temp.common_event_id = 10 #>Appeler l'évent de sortie surf
      end
      return false
    elsif(@surfing and sys_tag == WaterFall)
      if self==$game_player
        $game_temp.common_event_id = 26 #> Appeler l'évènement de cascade
      end
      return false
    end
    return true if skip_event
    # 全イベントのループ
    for event in game_map.events.values
      # イベントの座標が移動先と一致した場合
#      if event.x == new_x and event.y == new_y and event.z == z
      if event.contact?(new_x, new_y, z)
        # すり抜け OFF なら
        unless event.through
          # 自分がイベントの場合
          if self != $game_player
            # 通行不可
            return false
          end
          # 自分がプレイヤーで、相手のグラフィックがキャラクターの場合
          unless event.character_name.empty? #if event.character_name != ""
            # 通行不可
            return false
          end
        end
      end
    end
    # プレイヤーの座標が移動先と一致した場合
    #if $game_player.x == new_x and $game_player.y == new_y and $game_player.z == z
    if $game_player.contact?(new_x, new_y, z)
      # すり抜け OFF なら
      unless $game_player.through
        # 自分のグラフィックがキャラクターの場合
        unless @character_name.empty? #if @character_name != ""
          # 通行不可
          return false
        end
      end
    end

    unless Yuki::FollowMe.is_player_follower?(self) or self==$game_player
      Yuki::FollowMe.each_follower do |event|
        #if event.x == new_x and event.y == new_y and event.z == z
        if event.contact?(new_x, new_y, z)
          return false
        end
      end
    end
    # 通行可
    return true
  end
  # Lock the character
  def lock
    # すでにロックされている場合
    if @locked
      # メソッド終了
      return
    end
    # ロック前の向きを保存
    @prelock_direction = @direction
    # プレイヤーの方を向く
    turn_toward_player
    # ロック中フラグをセット
    @locked = true
  end
  # is the character locked ?
  def lock?
    return @locked
  end
  # unlock the character
  def unlock
    # ロックされていない場合
    unless @locked
      # メソッド終了
      return
    end
    # ロック中フラグをクリア
    @locked = false
    # 向き固定でない場合
    unless @direction_fix
      # ロック前の向きが保存されていれば
      if @prelock_direction != 0
        # ロック前の向きを復帰
        @direction = @prelock_direction
      end
    end
  end
  # Warps the character on the Map to specific coordinates.
  # Adjust the z position of the character.
  # @param x [Integer] new x position of the character
  # @param y [Integer] new y position of the character
  def moveto(x, y)
    @x = x % $game_map.width
    @y = y % $game_map.height
    @real_x = @x * 128
    @real_y = @y * 128
    @prelock_direction = 0
    if(@follower)
      x=@x
      y=@y
      @follower.moveto(x,y)
      @follower.direction=@direction
    end
    #> Gestion du SystemTag
    if $scene.class != Scene_Map
      if self == $game_player
        @z = 1 unless @z
        return
      end
    end
    sys_tag = self.system_tag
    if (sys_tag == BridgeRL or sys_tag == BridgeUD)
      @z = $game_map.priorities[$game_map.get_tile(@x, @y)].to_i + 1
    elsif ZTag.include?(sys_tag)
      @z = ZTag.index(sys_tag)
    else
      @z = 1
    end
    particle_push
  end
  # Return the x position of the sprite on the screen
  # @return [Integer]
  def screen_x
    # 実座標とマップの表示位置から画面座標を求める
    return (@real_x - $game_map.display_x + 5) / 4 + 16 # +3 => +5
  end
  # Return the y position of the sprite on the screen
  # @return [Integer]
  def screen_y
    # 実座標とマップの表示位置から画面座標を求める
    y = (@real_y - $game_map.display_y + 5) / 4 + 32 # +3 => +5
    # ジャンプカウントに応じて Y 座標を小さくする
    if @jump_count >= @jump_peak
      n = @jump_count - @jump_peak
    else
      n = @jump_peak - @jump_count
    end
    return y - (@jump_peak * @jump_peak - n * n) / 2
  end
  # Return the x position of the shadow of the character on the screen
  # @return [Integer]
  def shadow_screen_x
    return (@real_x - $game_map.display_x + 5) / 8 + 8 # +3 => +5
  end
  # Return the y position of the shadow of the character on the screen
  # @return [Integer]
  def shadow_screen_y
    return (@real_y - $game_map.display_y + 5) / 8 + 17 # +3 => +5
  end
  # Return the z superiority of the sprite of the character
  # @param height [Integer] height of a frame of the character (ignored)
  # @return [Integer]
  def screen_z(height = 0)
    # 最前面に表示フラグが ON の場合
    if @always_on_top
      # 無条件に 999
      return 999
    end
    # 実座標とマップの表示位置から画面座標を求める
    z = (@real_y - $game_map.display_y + 3) / 4 + 32 * @z
    # タイルの場合
    if @tile_id > 0
      # タイルのプライオリティ * 32 を足す
      return z + $game_map.priorities[@tile_id] * 32
    # キャラクターの場合
    else
      # 高さが 32 を超えていれば 31 を足す
      return z + 31
      #return z + ((height > 64) ? 31 : 0)
    end
  end
  # bush_depth of the sprite of the character
  # @return [Integer]
  def bush_depth
    # タイルの場合、または最前面に表示フラグが ON の場合
    if @tile_id > 0 or @always_on_top
      return 0
    end
    return 12 if @in_swamp #> Ajout des marais
    # ジャンプ中以外で茂み属性のタイルなら 12、それ以外なら 0
    if @jump_count == 0 and $game_map.bush?(@x, @y)
      return 12
    else
      return 0
    end
  end
  # terrain tag on which the character steps
  # @return [Integer, nil]
  def terrain_tag
    return $game_map.terrain_tag(@x, @y)
  end
end
