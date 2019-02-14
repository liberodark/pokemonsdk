#encoding: utf-8

# Describe the Map processing
class Game_Map
  # If the player is always on the center of the screen
  CenterPlayer = ::Config::CenterPlayer
  attr_accessor :tileset_name             # タイルセット ファイル名
  attr_accessor :autotile_names           # オートタイル ファイル名
  attr_accessor :panorama_name            # パノラマ ファイル名
  attr_accessor :panorama_hue             # パノラマ 色相
  attr_accessor :fog_name                 # フォグ ファイル名
  attr_accessor :fog_hue                  # フォグ 色相
  attr_accessor :fog_opacity              # フォグ 不透明度
  attr_accessor :fog_blend_type           # フォグ ブレンド方法
  attr_accessor :fog_zoom                 # フォグ 拡大率
  attr_accessor :fog_sx                   # フォグ SX
  attr_accessor :fog_sy                   # フォグ SY
  attr_accessor :battleback_name          # バトルバック ファイル名
  attr_accessor :display_x                # 表示 X 座標 * 128
  attr_accessor :display_y                # 表示 Y 座標 * 128
  attr_accessor :need_refresh             # リフレッシュ要求フラグ
  attr_reader   :passages                 # 通行 テーブル
  attr_reader   :priorities               # プライオリティ テーブル
  attr_reader   :terrain_tags             # 地形タグ テーブル
  attr_reader   :events                   # イベント
  attr_reader   :fog_ox                   # フォグ 原点 X 座標
  attr_reader   :fog_oy                   # フォグ 原点 Y 座標
  attr_reader   :fog_tone                 # フォグ 色調
  # Initialize the default Game_Map object
  def initialize
    @map_id = 0
    @display_x = 0
    @display_y = 0
  end
  # setup the Game_Map object with the right Map data
  # @param map_id [Integer] the ID of the map
  def setup(map_id)
    Yuki::ElapsedTime.start(:map_loading)
    # マップ ID を @map_id に記憶
    @map_id = map_id
    # マップをファイルからロードし、@map に設定
    @map = Yuki::MapLinker.load_map(@map_id)
    Yuki::ElapsedTime.show(:map_loading, 'MapLinker.load_map took')
    # 公開インスタンス変数にタイルセットの情報を設定
    load_systemtags
    tileset = $data_tilesets[@map.tileset_id]
    # -- Scheduler.start(:on_getting_tileset_name)
    @tileset_name = Yuki::MapLinker.tileset_name # -- get_tileset_name($game_temp.tileset_name || tileset.tileset_name)
    # -- $game_temp.tileset_name = nil
    @autotile_names = tileset.autotile_names
    @panorama_name = tileset.panorama_name
    @panorama_hue = tileset.panorama_hue
    @fog_name = tileset.fog_name
    @fog_hue = tileset.fog_hue
    @fog_opacity = tileset.fog_opacity
    @fog_blend_type = tileset.fog_blend_type
    @fog_zoom = tileset.fog_zoom
    @fog_sx = tileset.fog_sx
    @fog_sy = tileset.fog_sy
    @battleback_name = tileset.battleback_name
    @passages = tileset.passages
    @priorities = tileset.priorities
    @terrain_tags = tileset.terrain_tags
    # 表示座標を初期化
    @display_x = 0
    @display_y = 0
    # リフレッシュ要求フラグをクリア
    @need_refresh = false
    # マップイベントのデータを設定
    env = $env
    @events = {}
    @map.events.each do |i, event|
      next if env.get_event_delete_state(i)
      event.name.force_encoding(Encoding::UTF_8) # £EncodingPatch
      @events[i] = Game_Event.new(@map_id, event)
    end
    Yuki::ElapsedTime.show(:map_loading, 'Loading events took')
    # コモンイベントのデータを設定
    @common_events = {}
    1.upto($data_common_events.size - 1) do |i|
      @common_events[i] = Game_CommonEvent.new(i)
    end
    Yuki::ElapsedTime.show(:map_loading, 'Loading common events took')
    # フォグの各情報を初期化
    @fog_ox = 0
    @fog_oy = 0
    @fog_tone = Tone.new(0, 0, 0, 0)
    @fog_tone_target = Tone.new(0, 0, 0, 0)
    @fog_tone_duration = 0
    @fog_opacity_duration = 0
    @fog_opacity_target = 0
    # スクロール情報を初期化
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
    load_follower if @next_setup_followers
  end
  # Returns the ID of the Map
  # @return [Integer]
  def map_id
    return @map_id
  end
  # Returns the width of the map
  # @return [Integer]
  def width
    return @map.width
  end
  # Returns the height of the map
  # @return [Integer]
  def height
    return @map.height
  end
  # Returns the encounter list
  # @deprecated Not used by the Core of PSDK because not precise enough to be used
  def encounter_list
    return @map.encounter_list
  end
  # Returns the encounter step of the map
  # @return [Integer] number of step the player must do before each encounter
  def encounter_step
    return @map.encounter_step
  end
  # Returns the tile matrix of the Map
  # @return [Table] a 3D table containing ids of tile
  def data
    return @map.data
  end
  # Auto play bgm and bgs of the map if defined
  def autoplay
    if @map.autoplay_bgm
      $game_system.bgm_play(@map.bgm)
    end
    if @map.autoplay_bgs
      $game_system.bgs_play(@map.bgs)
    end
  end
  # Refresh events and common events of the map
  def refresh
    # マップ ID が有効なら
    if @map_id > 0
      # すべてのマップイベントをリフレッシュ
      for event in @events.values
        event.refresh
      end
      # すべてのコモンイベントをリフレッシュ
      for common_event in @common_events.values
        common_event.refresh
      end
    end
    # リフレッシュ要求フラグをクリア
    @need_refresh = false
  end
  # Scrolls the map down
  # @param distance [Integer] distance in y to scroll
  def scroll_down(distance)
    unless CenterPlayer
      @display_y = [@display_y + distance, (self.height - 15) * 128].min
    else
      @display_y = @display_y + distance
    end
  end
  # Scrolls the map left
  # @param distance [Integer] distance in -x to scroll
  def scroll_left(distance)
    unless CenterPlayer
      @display_x = [@display_x - distance, 0].max
    else
      @display_x = @display_x - distance
    end
  end
  # Scrolls the map right
  # @param distance [Integer] distance in x to scroll
  def scroll_right(distance)
    unless CenterPlayer
      @display_x = [@display_x + distance, (self.width - 20) * 128].min
    else
      @display_x = @display_x + distance
    end
  end
  # Scrolls the map up
  # @param distance [Integer] distance in -y to scroll
  def scroll_up(distance)
    unless CenterPlayer
      @display_y = [@display_y - distance, 0].max
    else
      @display_y = @display_y - distance
    end
  end
  # Tells if the x,y coordinate is valid or not (inside of bounds)
  # @param x [Integer] the x coordinate 
  # @param y [Integer] the y coordinate
  # @return [Boolean] if it's valid or not
  def valid?(x, y)
    return (x >= 0 and x < width and y >= 0 and y < height)
  end
  # Tells if the tile front/current tile is passsable or not
  # @param x [Integer] x position on the Map
  # @param y [Integer] y position on the Map
  # @param d [Integer] direction : 2, 4, 6, 8, 0. 0 = current position
  # @param self_event [Game_Event, nil] the "tile" event to ignore
  # @return [Boolean] if the front/current tile is passable
  def passable?(x, y, d, self_event = nil)
    # 与えられた座標がマップ外の場合
    unless valid?(x, y)
      # 通行不可
      return false
    end
    # 方向 (0,2,4,6,8,10) から 障害物ビット (0,1,2,4,8,0) に変換
    bit = (1 << (d / 2 - 1)) & 0x0f
    # すべてのイベントでループ
    for event in events.values
      # 自分以外のタイルと座標が一致した場合
      if event.tile_id >= 0 and event != self_event and
         event.x == x and event.y == y and not event.through
        # 障害物ビットがセットされている場合
        if @passages[event.tile_id] & bit != 0
          # 通行不可
          return false
        # 全方向の障害物ビットがセットされている場合
        elsif @passages[event.tile_id] & 0x0f == 0x0f
          # 通行不可
          return false
        # それ以外で プライオリティが 0 の場合
        elsif @priorities[event.tile_id] == 0
          # 通行可
          return true
        end
      end
    end
    # レイヤーの上から順に調べるループ
    for i in [2, 1, 0]
      # タイル ID を取得
      tile_id = data[x, y, i]
      # タイル ID 取得失敗
      if tile_id == nil
        # 通行不可
        return false
      # 障害物ビットがセットされている場合
      elsif @passages[tile_id] & bit != 0
        # 通行不可
        return false
      # 全方向の障害物ビットがセットされている場合
      elsif @passages[tile_id] & 0x0f == 0x0f
        # 通行不可
        return false
      # それ以外で プライオリティが 0 の場合
      elsif @priorities[tile_id] == 0
        # 通行可
        return true
      end
    end
    # 通行可
    return true
  end
  # Tells if the tile is a bush tile
  # @param x [Integer] x coordinate of the tile
  # @param y [Integer] y coordinate of the tile
  # @return [Boolean]
  def bush?(x, y)
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return false
        elsif @passages[tile_id] & 0x40 == 0x40
          return true
        end
      end
    end
    return false
  end
  # カウンター判定 (no idea, need GTranslate)
  # @param x [Integer] x coordinate of the tile
  # @param y [Integer] y coordinate of the tile
  # @return [Boolean]
  def counter?(x, y)
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return false
        elsif @passages[tile_id] & 0x80 == 0x80
          return true
        end
      end
    end
    return false
  end
  # Returns the tag of the tile
  # @param x [Integer] x coordinate of the tile
  # @param y [Integer] y coordinate of the tile
  # @return [Integer, nil] Tag of the tile
  def terrain_tag(x, y)
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return 0
        elsif @terrain_tags[tile_id] and @terrain_tags[tile_id] > 0
          return @terrain_tags[tile_id]
        end
      end
    end
    return 0
  end
  # Unused
  # @param x [Integer] x position on the Map
  # @param y [Integer] y position on the Map
  # @return [Integer] the id of the event on the coordinates
  def check_event(x, y)
    for event in $game_map.events.values
      if event.x == x and event.y == y
        return event.id
      end
    end
  end
  # Starts a scroll processing
  # @param direction [Integer] the direction to scroll
  # @param distance [Integer] the distance to scroll
  # @param speed [Integer] the speed of the scroll processing
  def start_scroll(direction, distance, speed)
    @scroll_direction = direction
    @scroll_rest = distance * 128
    @scroll_speed = speed
  end
  # is the map scrolling ?
  # @return [Boolean]
  def scrolling?
    return @scroll_rest > 0
  end
  # Starts a fog tone change process
  # @param tone [Tone] the new tone of the fog
  # @param duration [Integer] the number of frame the tone change will take
  def start_fog_tone_change(tone, duration)
    @fog_tone_target = tone.clone
    @fog_tone_duration = duration
    if @fog_tone_duration == 0
      @fog_tone = @fog_tone_target.clone
    end
  end
  # Starts a fog opacity change process
  # @param opacity [Integer] the new opacity of the fog
  # @param duration [Integer] the number of frame the opacity change will take
  def start_fog_opacity_change(opacity, duration)
    @fog_opacity_target = opacity * 1.0
    @fog_opacity_duration = duration
    if @fog_opacity_duration == 0
      @fog_opacity = @fog_opacity_target
    end
  end
  # Update the Map processing
  def update
    # 必要ならマップをリフレッシュ
    if $game_map.need_refresh
      refresh
    end
    # スクロール中の場合
    if @scroll_rest > 0
      # スクロール速度からマップ座標系での距離に変換
      distance = 2 ** @scroll_speed
      # スクロールを実行
      case @scroll_direction
      when 2  # 下
        scroll_down(distance)
      when 4  # 左
        scroll_left(distance)
      when 6  # 右
        scroll_right(distance)
      when 8  # 上
        scroll_up(distance)
      end
      # スクロールした距離を減算
      @scroll_rest -= distance
    end
    #>Partie édition des SystemTag
#    return if Yuki::SystemTag.running?
    # マップイベントを更新
    @events.each_value { |event| event.update }
    # コモンイベントを更新
    @common_events.each_value { |event| event.update }
#    t2=Time.new
#    p t2-t1 if Input.trigger?(Input::F6)
    # フォグのスクロール処理
    @fog_ox -= @fog_sx / 8.0
    @fog_oy -= @fog_sy / 8.0
    # フォグの色調変更処理
    if @fog_tone_duration >= 1
      d = @fog_tone_duration
      target = @fog_tone_target
      @fog_tone.red = (@fog_tone.red * (d - 1) + target.red) / d
      @fog_tone.green = (@fog_tone.green * (d - 1) + target.green) / d
      @fog_tone.blue = (@fog_tone.blue * (d - 1) + target.blue) / d
      @fog_tone.gray = (@fog_tone.gray * (d - 1) + target.gray) / d
      @fog_tone_duration -= 1
    end
    # フォグの不透明度変更処理
    if @fog_opacity_duration >= 1
      d = @fog_opacity_duration
      @fog_opacity = (@fog_opacity * (d - 1) + @fog_opacity_target) / d
      @fog_opacity_duration -= 1
    end
  end
end
