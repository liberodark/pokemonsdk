#encoding: utf-8

# Describe an Event during the Map display process
class Game_Event < Game_Character
  # Tag inside an event that put it in the surfing state
  SurfNTag = "surf_"
  # If named like this, this event is an invisible object
  InvisibleTag = "OBJ_INVISIBLE"
  # Tag that sets the event in an invisible state (not triggerd unless in front of it)
  InvisibleTag2 = "invisible_"
  # Tag that tells the event to always take the character_name of the first page when page change
  AutoCharset_Tag = "$"
  attr_reader   :trigger                  # トリガー
  attr_reader   :list                     # 実行内容
  attr_reader   :starting                 # 起動中フラグ
  attr_reader :event # Event data
  attr_reader :objetInvisible
  attr_reader :erased
  # Initialize the Game_Event with its map_id and its RPG::Event data
  # @param map_id [Integer] id of the map where the event is instanciated
  # @param event [RPG::Event] data of the event
  def initialize(map_id, event)
    super()
    @map_id = map_id
    @event = event
    @id = @event.id
    @original_map = event.original_map || map_id
    @original_id = event.original_id || @id
    @erased = false
    @starting = false
    @through = true
    @autocharset = event.name.include?(AutoCharset_Tag)
    # 初期位置に移動
    moveto(@event.x, @event.y)
    @surfing = event.name.include?(SurfNTag)
    @objetInvisible = (event.name == InvisibleTag || event.name.include?(InvisibleTag2))
    refresh
  end
  # Sets @starting to false allowing the event to move with its default move route
  def clear_starting
    @starting = false
  end
  # Tells if the Event can start
  # @return [Boolean]
  def over_trigger?
    # グラフィックがキャラクターで、すり抜け状態ではない場合
    if !@character_name.empty? and !@through or @objetInvisible#if @character_name != "" and not @through or @objetInvisible
      # 起動判定は正面
      return false
    end
    # マップ上でこの位置が通行不可能な場合
    unless $game_map.passable?(@x, @y, 0)
      # 起動判定は正面
      return false
    end
    # 起動判定は同位置
    return true
  end
  # Starts the event if possible
  def start
    # 実行内容が空でない場合
    if @list.size > 1
      @starting = true
    end
  end
  # Remove the event from the map
  def erase
    @erased = true
    @x = -10
    @y = -10
    @opacity = 0
    $game_map.event_erased = true
    refresh
  end
  # Refresh the event : check if an other page is valid and if so, refresh the graphics and command list
  def refresh
    # ローカル変数 new_page を初期化
    new_page = nil
    # 一時消去されていない場合
    unless @erased
      # 番号の大きいイベントページから順に調べる
      for page in @event.pages.reverse
        # イベント条件を c で参照可能に
        c = page.condition
        # スイッチ 1 条件確認
        if c.switch1_valid
          if $game_switches[c.switch1_id] == false
            next
          end
        end
        # スイッチ 2 条件確認
        if c.switch2_valid
          if $game_switches[c.switch2_id] == false
            next
          end
        end
        # 変数 条件確認
        if c.variable_valid
          if $game_variables[c.variable_id] < c.variable_value
            next
          end
        end
        # セルフスイッチ 条件確認
        if c.self_switch_valid
          key = [@original_map, @original_id, c.self_switch_ch]
          if $game_self_switches[key] != true
            next
          end
        end
        # ローカル変数 new_page を設定
        new_page = page
        # ループを抜ける
        break
      end
    end
    # 前回と同じイベントページの場合
    if new_page == @page
      # メソッド終了
      return
    end
    # @page に現在のイベントページを設定
    @page = new_page
    # 起動中フラグをクリア
    clear_starting
    # 条件を満たすページがない場合
    if @page == nil
      # 各インスタンス変数を設定
      @tile_id = 0
      @character_name = nil.to_s
      @character_hue = 0
      @move_type = 0
      @through = true
      @trigger = nil
      @list = nil
      @interpreter = nil
      # メソッド終了
      return
    end
    # 各インスタンス変数を設定
    @tile_id = @page.graphic.tile_id
    # Patch auto charset
    if @autocharset
      @character_name = @event.pages[0].graphic.character_name
      @character_hue = @event.pages[0].graphic.character_hue
    else
      @character_name = @page.graphic.character_name
      @character_hue = @page.graphic.character_hue
    end
    if @original_direction != @page.graphic.direction
      @direction = @page.graphic.direction
      @original_direction = @direction
      @prelock_direction = 0
    end
    if @original_pattern != @page.graphic.pattern
      @pattern = @page.graphic.pattern
      @original_pattern = @pattern
    end
    @opacity = @page.graphic.opacity
    @blend_type = @page.graphic.blend_type
    @move_type = @page.move_type
    @move_speed = @page.move_speed
    @move_frequency = @page.move_frequency
    @move_route = @page.move_route
    @move_route_index = 0
    @move_route_forcing = false
    @walk_anime = @page.walk_anime
    @step_anime = @page.step_anime
    @direction_fix = @page.direction_fix
    @through = @page.through
    @always_on_top = @page.always_on_top
    @trigger = @page.trigger
    @list = @page.list
    @interpreter = nil
    # トリガーが [並列処理] の場合
    if @trigger == 4
      # 並列処理用インタプリタを作成
      @interpreter = Interpreter.new
    end
    # 自動イベントの起動判定
    check_event_trigger_auto
  end
  # Check if the event touch the player and start it if so
  # @param x [Integer] the x position to check
  # @param y [Integer] the y position to check
  def check_event_trigger_touch(x, y)
    # イベント実行中の場合
    if $game_system.map_interpreter.running?
      return
    end
    # トリガーが [イベントから接触] かつプレイヤーの座標と一致した場合
    if @trigger == 2 and x == $game_player.x and y == $game_player.y
      # ジャンプ中以外で、起動判定が正面のイベントなら
      if not jumping? and not over_trigger?
        start
      end
    end
  end
  # Check if the event starts automaticaly and start if so
  def check_event_trigger_auto
    # トリガーが [イベントから接触] かつプレイヤーの座標と一致した場合
    if @trigger == 2 and @x == $game_player.x and @y == $game_player.y and !$game_temp.player_transferring
      # ジャンプ中以外で、起動判定が同位置のイベントなら
      if not jumping? and over_trigger?
        start
      end
    end
    # トリガーが [自動実行] の場合
    if @trigger == 3
      start
    end
  end
  # Update the Game_Character and its internal Interpreter
  def update
    super
    # 自動イベントの起動判定
    check_event_trigger_auto
    # 並列処理が有効の場合
    if @interpreter != nil
      # 実行中でない場合
      unless @interpreter.running?
        # イベントをセットアップ
        @interpreter.setup(@list, @event.id)
      end
      # インタプリタを更新
      @interpreter.update
    end
  end
end
