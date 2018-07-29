#encoding: utf-8

# Management of the player displacement on the Map
class Game_Player < Game_Character
  # 4 time the x position of the Game_Player sprite
  CENTER_X = (320 - 16) * 4
  # 4 time the y position of the Game_Player sprite
  CENTER_Y = (240 - 16) * 4
  # Name of the bump sound when the player hit a wall
  BUMP_FILE = "Audio/SE/bump"
  # true if the player is on the back wheel of its Acro bike
  # @return [Boolean]
  attr_accessor :acro_appearence
  # Default initializer
  def initialize
    super
    @wturn = 0
    @bump_count = 0 #A conserver pour BUMP a la Pokémon
    @on_acro_bike = false
    @acro_count = 0
    ## @cant_bump = false
  end
  # is the tile in front of the player passable ? / Plays a BUMP SE in some conditions
  # @param x [Integer] x position on the Map
  # @param y [Integer] y position on the Map
  # @param d [Integer] direction : 2, 4, 6, 8, 0. 0 = current position
  # @return [Boolean] if the front/current tile is passable
  def passable?(x, y, d)
    if $DEBUG and Input::Keyboard.press?(Input::Keyboard::LControl)# or Yuki::SystemTag.running?
      # 通行可
      return false if x == 0 and d == 4
      return false if y == 0 and d == 8
      return false if d == 6 and (x+1) == $game_map.width
      return false if d == 2 and (y+1) == $game_map.height
      return true
    end
    #> Check passable avec acro bike
    result = acro_passable_check(d, super)
=begin
    #Lignes pour faire le bump à la Pokémon, faut les conserver !!!
    if(!result and @bump_count < 1 and $game_temp.common_event_id == 0) # 
      #Audio.se_play(BUMP_FILE)
      puts "bmp"
      @bump_count = 30
      @step_anime = true if @lastdir4 != 0 and !@surfing and !@sliding
    end
=end
    return result
  end
  # Adjust the map display according to the given position
  # @param x [Integer] the x position on the MAP
  # @param y [Integer] the y position on the MAP
  def center(x, y)
    unless Game_Map::CenterPlayer
      max_x = ($game_map.width - 20) * 128
      max_y = ($game_map.height - 15) * 128
      $game_map.display_x = [0, [x * 128 - CENTER_X, max_x].min].max
      $game_map.display_y = [0, [y * 128 - CENTER_Y, max_y].min].max
    else
      $game_map.display_x = x * 128 - CENTER_X
      $game_map.display_y = y * 128 - CENTER_Y
    end
  end
  # Warp the player to a specific position. The map display will be centered
  # @param x [Integer] the x position on the MAP
  # @param y [Integer] the y position on the MAP
  def moveto(x, y)
    super
    # センタリング
    center(x, y)
    # エンカウント カウントを作成
    make_encounter_count
  end
  # Increases a step and displays related things
  def increase_steps
    super
    # 移動ルート強制中ではない場合
    unless @move_route_forcing or $game_system.map_interpreter.running? or 
      $game_temp.message_window_showing or @sliding
      #>Interractions en fonction des déplacements
      data = $pokemon_party.increase_steps
      #>Affichage des interractions si il y en as.
      $scene.display_step_info(data) if data.size > 0 and $scene.class == Scene_Map
      # game party . check map slip damage : removed
    end
  end
  # Returns the number of steps remaining to the next encounter
  def encounter_count
    return @encounter_count
  end
  # Generate the number of steps remaining to the next encounter
  def make_encounter_count
    # サイコロを 2 個振るイメージ
    if $game_map.map_id != 0
      n = $game_map.encounter_step
      @encounter_count = rand(n) + rand(n) + 1
    end
  end
  # Refresh the player graphics
  def refresh
    # パーティ人数が 0 人の場合
    if $game_party.actors.size == 0
      # キャラクターのファイル名と色相をクリア
      @character_name = nil.to_s
      @character_hue = 0
      # メソッド終了
      return
    end
    # 先頭のアクターを取得
    actor = $game_party.actors[0]
    # キャラクターのファイル名と色相を設定
    @character_name = actor.character_name
    @character_hue = actor.character_hue
    # 不透明度と合成方法を初期化
    @opacity = 255
    @blend_type = 0
  end
  # Check if there's an event trigger on the tile where the player stands
  # @param triggers [Array<Integer>] the list of triggers to check
  # @return [Boolean]
  def check_event_trigger_here(triggers)
    result = false
    # イベント実行中の場合
    if $game_system.map_interpreter.running?
      return result
    end
    z = @z
    # 全イベントのループ
    for event in $game_map.events.values
      # イベントの座標とトリガーが一致した場合
      #if event.x == @x and event.y == @y and event.z == z and triggers.include?(event.trigger)
      if event.contact?(@x, @y, z) and triggers.include?(event.trigger)
        # ジャンプ中以外で、起動判定が同位置のイベントなら
        if not event.jumping? and event.over_trigger?
          event.start
          result = true
        end
      end
    end
    return result
  end
  # Check if there's an event trigger in front of the player
  # @param triggers [Array<Integer>] the list of triggers to check
  # @return [Boolean]
  def check_event_trigger_there(triggers)
    result = false
    d = @direction
    # イベント実行中の場合
    if $game_system.map_interpreter.running?
      return result
    end
    # 正面の座標を計算
    new_x = @x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = @y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    z = @z
    # 全イベントのループ
    for event in $game_map.events.values
      # イベントの座標とトリガーが一致した場合
#      if event.x == new_x and event.y == new_y and event.z == z and
      if event.contact?(new_x, new_y, z) and triggers.include?(event.trigger)
        # ジャンプ中以外で、起動判定が正面のイベントなら
        if not event.jumping? and not event.over_trigger?
          event.start
          result = true
        end
      end
    end
    z = @z
    # 該当するイベントが見つからなかった場合
    if result == false
      # 正面のタイルがカウンターなら
      if $game_map.counter?(new_x, new_y)
        # 1 タイル奥の座標を計算
        new_x += (d == 6 ? 1 : d == 4 ? -1 : 0)
        new_y += (d == 2 ? 1 : d == 8 ? -1 : 0)
        # 全イベントのループ
        for event in $game_map.events.values
          # イベントの座標とトリガーが一致した場合
          #if event.x == new_x and event.y == new_y and event.z == z and triggers.include?(event.trigger)
          if event.contact?(new_x, new_y, z) and triggers.include?(event.trigger)
            # ジャンプ中以外で、起動判定が正面のイベントなら
            if not event.jumping? and not event.over_trigger?
              event.start
              result = true
            end
          end
        end
      end
    end

    unless result
      #> Ajout plongée
      if (terrain_tag == 6 and (system_tag == TSea or system_tag == TUnderWater))
        $game_temp.common_event_id = 29 #>Event commun de pongée
      #> Ajout de HeadButt
      elsif($game_map.system_tag(new_x, new_y) == HeadButt)
        $game_temp.common_event_id = 20 #> Event commun de headbutt
      #>Ajout de surf
      elsif($game_map.passable?(x, y, d, nil) and z <= 1)
        new_x = @x + (d == 6 ? 1 : d == 4 ? -1 : 0)
        new_y = @y + (d == 2 ? 1 : d == 8 ? -1 : 0)
        sys_tag = $game_map.system_tag(new_x, new_y)
        if(!@surfing and (sys_tag == TPond or sys_tag == TSea))
          $game_temp.common_event_id = 9 #>Event commun de surf
        end
      end
    end

    #>Ajout Follower
    unless result
      if(@follower)
        new_x = @x + (d == 6 ? 1 : d == 4 ? -1 : 0)
        new_y = @y + (d == 2 ? 1 : d == 8 ? -1 : 0)
        if(@follower.x == new_x and @follower.y == new_y)
          @follower.turn_toward_player
          $game_temp.common_event_id = 5 #> Appel Follower
        end
      end
    end

    return result
  end
  # Check if the player touch an event and start it if so
  # @param x [Integer] the x position to check
  # @param y [Integer] the y position to check
  def check_event_trigger_touch(x, y)
    result = false
    # イベント実行中の場合
    if $game_system.map_interpreter.running?
      return result
    end
    z = @z
    # 全イベントのループ
    for event in $game_map.events.values
      # イベントの座標とトリガーが一致した場合
      #if event.x == x and event.y == y and event.z == z and [1,2].include?(event.trigger)
      if event.contact?(x, y, z) and [1,2].include?(event.trigger)
        # ジャンプ中以外で、起動判定が正面のイベントなら
        if not event.jumping? and not event.over_trigger?
          event.start
          result = true
        end
      end
    end
    return result
  end
  # Update the player movements according to inputs
  def update
    # ローカル変数に移動中かどうかを記憶
    last_moving = moving?
    # 移動中、イベント実行中、移動ルート強制中、
    # メッセージウィンドウ表示中のいずれでもない場合
    unless moving? or $game_system.map_interpreter.running? or
           @move_route_forcing or $game_temp.message_window_showing or @sliding# or follower_sliding?
      player_update_move
    else
      @step_anime = false if $game_system.map_interpreter.running?
    end
    @wturn -= 1 if @wturn > 0
    last_real_x = @real_x
    last_real_y = @real_y
    super
    #_BUMP
=begin
    if(@cant_bump and moving?)
      @cant_bump=false
    end
=end
    # キャラクターが下に移動し、かつ画面上の位置が中央より下の場合
    if @real_y > last_real_y and @real_y - $game_map.display_y > CENTER_Y
      # マップを下にスクロール
      $game_map.scroll_down(@real_y - last_real_y)
    end
    # キャラクターが左に移動し、かつ画面上の位置が中央より左の場合
    if @real_x < last_real_x and @real_x - $game_map.display_x < CENTER_X
      # マップを左にスクロール
      $game_map.scroll_left(last_real_x - @real_x)
    end
    # キャラクターが右に移動し、かつ画面上の位置が中央より右の場合
    if @real_x > last_real_x and @real_x - $game_map.display_x > CENTER_X
      # マップを右にスクロール
      $game_map.scroll_right(@real_x - last_real_x)
    end
    # キャラクターが上に移動し、かつ画面上の位置が中央より上の場合
    if @real_y < last_real_y and @real_y - $game_map.display_y < CENTER_Y
      # マップを上にスクロール
      $game_map.scroll_up(last_real_y - @real_y)
    end
#    return if Yuki::SystemTag.running?
    # 移動中ではない場合
    unless moving? or @sliding
      # 前回プレイヤーが移動中だった場合
      if last_moving
        # 同位置のイベントとの接触によるイベント起動判定
        result = check_event_trigger_here([1,2])
        # 起動したイベントがない場合
        if result == false
          # デバッグモードが ON かつ CTRL キーが押されている場合を除き
          unless $DEBUG and Input.press?(:CTRL)
            # エンカウント カウントダウン
            if @encounter_count > 0
              @encounter_count -= 1
            end
          end
        end
      end
      # C ボタンが押された場合
      if Input.trigger?(:A)
        # 同位置および正面のイベント起動判定
        check_event_trigger_here([0])
        check_event_trigger_there([0,1,2])
      end
    end
  end
end
