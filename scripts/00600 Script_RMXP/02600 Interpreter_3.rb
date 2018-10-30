#encoding: utf-8

class Interpreter_RMXP
  # Command that starts a message display, if followed by a choice/input num command, displays the choice/input num in the meantime
  def command_101
    # ほかの文章が message_text に設定済みの場合
    if $game_temp.message_text != nil
      # 終了
      return false
    end
    $game_player.look_to(@event_id) unless $game_switches[::Yuki::Sw::MSG_Noturn]
    # メッセージ終了待機中フラグおよびコールバックを設定
    @message_waiting = true
    $game_temp.message_proc = Proc.new { @message_waiting = false }
    text = @list[@index].parameters[0]
      .force_encoding(Encoding::UTF_8) #£EncodingPatch
    # message_text に 1 行目を設定
    $game_temp.message_text = text + "\n"
    line_count = 1
    # ループ
    loop do
      # 次のイベントコマンドが文章 2 行目以降の場合
      if @list[@index+1].code == 401
        # message_text に 2 行目以降を追加
        text = @list[@index+1].parameters[0]
          .force_encoding(Encoding::UTF_8) #£EncodingPatch
        $game_temp.message_text += text + "\n"
        line_count += 1
      # イベントコマンドが文章 2 行目以降ではない場合
      else
        # 次のイベントコマンドが選択肢の表示の場合
        if @list[@index+1].code == 102
          # 選択肢が画面に収まる場合
          if @list[@index+1].parameters[0].size <= 5 - line_count
            # インデックスを進める
            @index += 1
            # 選択肢のセットアップ
#            $game_temp.choice_start = line_count
            setup_choices(@list[@index].parameters)
          end
        # 次のイベントコマンドが数値入力の処理の場合
        elsif @list[@index+1].code == 103
          # 数値入力ウィンドウが画面に収まる場合
          if line_count < 4
            # インデックスを進める
            @index += 1
            # 数値入力のセットアップ
            $game_temp.num_input_start = line_count
            $game_temp.num_input_variable_id = @list[@index].parameters[0]
            $game_temp.num_input_digits_max = @list[@index].parameters[1]
          end
        end
        # 継続
        return true
      end
      # インデックスを進める
      @index += 1
    end
  end
  # Command that display a choice if possible (no message)
  def command_102
    # 文章が message_text に設定済みの場合
    if $game_temp.message_text != nil
      # 終了
      return false
    end
    # メッセージ終了待機中フラグおよびコールバックを設定
    @message_waiting = true
    $game_temp.message_proc = Proc.new { @message_waiting = false }
    # 選択肢のセットアップ
    $game_temp.message_text = ""
    $game_temp.choice_start = 0
    setup_choices(@parameters)
    # 継続
    return true
  end
  # [**] の場合
  def command_402
    # 該当する選択肢が選択されている場合
    if @branch[@list[@index].indent] == @parameters[0]
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end
  # キャンセルの場合
  def command_403
    # 選択肢がキャンセルされている場合
    if @branch[@list[@index].indent] == 4
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end
  # Display an input number if possible (no message)
  def command_103
    # 文章が message_text に設定済みの場合
    if $game_temp.message_text != nil
      # 終了
      return false
    end
    # メッセージ終了待機中フラグおよびコールバックを設定
    @message_waiting = true
    $game_temp.message_proc = Proc.new { @message_waiting = false }
    # 数値入力のセットアップ
    $game_temp.message_text = nil.to_s
    $game_temp.num_input_start = 0
    $game_temp.num_input_variable_id = @parameters[0]
    $game_temp.num_input_digits_max = @parameters[1]
    # 継続
    return true
  end
  # Change the message settings (position / frame type)
  def command_104
    # メッセージ表示中の場合
    if $game_temp.message_window_showing
      # 終了
      return false
    end
    # 各オプションを変更
    $game_system.message_position = @parameters[0]
    $game_system.message_frame = @parameters[1]
    # 継続
    return true
  end
  # Start a store button id to variable process
  def command_105
    # ボタン入力用の変数 ID を設定
    @button_input_variable_id = @parameters[0]
    # インデックスを進める
    @index += 1
    # 終了
    return false
  end
  # Wait 2 times the number of frame requested
  def command_106
    # ウェイトカウントを設定
    @wait_count = @parameters[0] * 2
    # 継続
    return true
  end
  # Conditionnal command
  def command_111
    # ローカル変数 result を初期化
    result = false
    # 条件判定
    case @parameters[0]
    when 0  # スイッチ
      result = ($game_switches[@parameters[1]] == (@parameters[2] == 0))
    when 1  # 変数
      value1 = $game_variables[@parameters[1]]
      if @parameters[2] == 0
        value2 = @parameters[3]
      else
        value2 = $game_variables[@parameters[3]]
      end
      case @parameters[4]
      when 0  # と同値
        result = (value1 == value2)
      when 1  # 以上
        result = (value1 >= value2)
      when 2  # 以下
        result = (value1 <= value2)
      when 3  # 超
        result = (value1 > value2)
      when 4  # 未満
        result = (value1 < value2)
      when 5  # 以外
        result = (value1 != value2)
      end
    when 2  # セルフスイッチ
      if @event_id > 0
        key = [$game_map.map_id, @event_id, @parameters[1]]
        if @parameters[2] == 0
          result = ($game_self_switches[key] == true)
        else
          result = ($game_self_switches[key] != true)
        end
      end
    when 3  # タイマー
      if $game_system.timer_working
        sec = $game_system.timer / 60#Graphics.frame_rate
        if @parameters[2] == 0
          result = (sec >= @parameters[1])
        else
          result = (sec <= @parameters[1])
        end
      end
    when 4  # アクター
      actor = PFM::BattleInterface.get_actor(@parameters[1]) #$game_actors[@parameters[1]]
      if actor != nil
        case @parameters[2]
        when 0  # パーティにいる Is in Party => Alive
          result = !actor.dead? #($game_party.actors.include?(actor))
        when 1  # 名前 / Name => Given Name
          result = (actor.given_name == @parameters[3])
        when 2  # スキル
          result = actor.skill_learnt?(@parameters[3], true)#(actor.skill_learn?(@parameters[3]))
        when 3  # 武器 / Weapon => Item holding
          result = (actor.item_holding == @parameters[3])#(actor.weapon_id == @parameters[3])
        when 4  # 防具 / Armor => Ability
          result = (actor.current_ability == @parameters[3])
=begin
          (actor.armor1_id == @parameters[3] or
                    actor.armor2_id == @parameters[3] or
                    actor.armor3_id == @parameters[3])
=end
        when 5  # ステート / Status
          result = (actor.status == @parameters[3]) #(actor.state?(@parameters[3]))
        end
      end
    when 5  # エネミー
      enemy = PFM::BattleInterface.get_enemy(@parameters[1]) #$game_troop.enemies[@parameters[1]]
      if enemy != nil
        case @parameters[2]
        when 0  # 出現している / Exists => alive
          result = !enemy.dead? #(enemy.exist?)
        when 1  # ステート
          result = (enemy.status == @parameters[3]) #(enemy.state?(@parameters[3]))
        end
      end
    when 6  # キャラクター
      character = get_character(@parameters[1])
      if character != nil
        result = (character.direction == @parameters[2])
      end
    when 7  # ゴールド
      if @parameters[2] == 0
        result = ($pokemon_party.money >= @parameters[1])#($game_party.gold >= @parameters[1])
      else
        result = ($pokemon_party.money <= @parameters[1])#($game_party.gold <= @parameters[1])
      end
    when 8  # アイテム / Item is owned
      result = $bag.has_item?(@parameters[1])#($game_party.item_number(@parameters[1]) > 0)
    when 9  # 武器
      result = false #($game_party.weapon_number(@parameters[1]) > 0)
    when 10  # 防具
      result = false #($game_party.armor_number(@parameters[1]) > 0)
    when 11  # ボタン
      result = (Input.press?(RGSS2LiteRGSS_Input[@parameters[1]]))
    when 12  # スクリプト
      result = eval_condition_script(@parameters[1])
    end
    # 判定結果をハッシュに格納
    @branch[@list[@index].indent] = result
    # 判定結果が真だった場合
    if @branch[@list[@index].indent] == true
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end

  # Function that execute a script for the conditions
  # @param script [String]
  def eval_condition_script(script)
    last_eval = Yuki::EXC.get_eval_script
    script = script.force_encoding('UTF-8')
    result = false
    Yuki::EXC.set_eval_script(script)
    Yuki::ErrorHandler.critical_section("Eval from condition (EVENT_ID = #{@event_id.to_i}).\nThe condition will not be valid.\nScript:\n#{script}") do
      result = eval(script) ? true : false
    end
    Yuki::EXC.set_eval_script(last_eval)
    return result
  end
  # それ以外の場合
  def command_411
    # 判定結果が偽だった場合
    if @branch[@list[@index].indent] == false
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end
  # ループ
  def command_112
    # 継続
    return true
  end
  # 以上繰り返し
  def command_413
    # インデントを取得
    indent = @list[@index].indent
    # ループ
    loop do
      # インデックスを戻す
      @index -= 1
      # このイベントコマンドが同レベルのインデントの場合
      if @list[@index].indent == indent
        # 継続
        return true
      end
    end
  end
  # ループの中断
  def command_113
    # インデントを取得
    indent = @list[@index].indent
    # インデックスを一時変数にコピー
    temp_index = @index
    # ループ
    loop do
      # インデックスを進める
      temp_index += 1
      # 該当するループが見つからなかった場合
      if temp_index >= @list.size-1
        # 継続
        return true
      end
      # このイベントコマンドが [以上繰り返し] かつインデントが浅い場合
      if @list[temp_index].code == 413 and @list[temp_index].indent < indent
        # インデックスを更新する
        @index = temp_index
        # 継続
        return true
      end
    end
  end
  # End the interpretation of the current event
  def command_115
    # イベントの終了
    command_end
    # 継続
    return true
  end
  # erase this event
  def command_116
    # イベント ID が有効の場合
    if @event_id > 0
      # イベントを消去
      $game_map.events[@event_id].erase
    end
    # インデックスを進める
    @index += 1
    # 終了
    return false
  end
  # Call a common event
  def command_117
    # コモンイベントを取得
    common_event = $data_common_events[@parameters[0]]
    # コモンイベントが有効の場合
    if common_event != nil
      # 子インタプリタを作成
      @child_interpreter = Interpreter.new(@depth + 1)
      @child_interpreter.setup(common_event.list, @event_id)
    end
    # 継続
    return true
  end
  # Label command
  def command_118
    # 継続
    return true
  end
  # jump to a label
  def command_119
    # ラベル名を取得
    label_name = @parameters[0]
    # 一時変数を初期化
    temp_index = 0
    # ループ
    loop do
      # 該当するラベルが見つからなかった場合
      if temp_index >= @list.size-1
        # 継続
        return true
      end
      # このイベントコマンドが指定された名前のラベルの場合
      if @list[temp_index].code == 118 and
         @list[temp_index].parameters[0] == label_name
        # インデックスを更新する
        @index = temp_index
        # 継続
        return true
      end
      # インデックスを進める
      temp_index += 1
    end
  end
end
