#encoding: utf-8

class Interpreter_RMXP
  # Start battle command
  def command_301
    # 無効なトループでなければ
    if $data_troops[@parameters[0]] != nil
      # バトル中断フラグをセット
      $game_temp.battle_abort = true
      # バトル呼び出しフラグをセット
      $game_temp.battle_calling = true
      $game_temp.battle_troop_id = @parameters[0]
      $game_temp.battle_can_escape = @parameters[1]
      $game_temp.battle_can_lose = @parameters[2]
      # コールバックを設定
      current_indent = @list[@index].indent
      $game_temp.battle_proc = Proc.new { |n| @branch[current_indent] = n }
    end
    # インデックスを進める
    @index += 1
    # 終了
    return false
  end

  # 勝った場合
  def command_601
    # バトル結果が勝ちの場合
    if @branch[@list[@index].indent] == 0
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end

  # 逃げた場合
  def command_602
    # バトル結果が逃げの場合
    if @branch[@list[@index].indent] == 1
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end

  # 負けた場合
  def command_603
    # バトル結果が負けの場合
    if @branch[@list[@index].indent] == 2
      # 分岐データを削除
      @branch.delete(@list[@index].indent)
      # 継続
      return true
    end
    # 条件に該当しない場合 : コマンドスキップ
    return command_skip
  end

  # Call a shop command
  def command_302
    # バトル中断フラグをセット
    $game_temp.battle_abort = true
    # ショップ呼び出しフラグをセット
    $game_temp.shop_calling = true
    # 商品リストに新しい項目を設定
    $game_temp.shop_goods = [@parameters]
    # ループ
    loop do
      # インデックスを進める
      @index += 1
      # 次のイベントコマンドがショップ 2 行目以降の場合
      if @list[@index].code == 605
        # 商品リストに新しい項目を追加
        $game_temp.shop_goods.push(@list[@index].parameters)
      # イベントコマンドがショップ 2 行目以降ではない場合
      else
        # 終了
        return false
      end
    end
  end

  # Name calling command
  def command_303
    # 無効なアクターでなければ
    if $data_actors[@parameters[0]] != nil
      # バトル中断フラグをセット
      $game_temp.battle_abort = true
      # 名前入力呼び出しフラグをセット
      $game_temp.name_calling = true
      $game_temp.name_actor_id = @parameters[0]
      $game_temp.name_max_char = @parameters[1]
    end
    # インデックスを進める
    @index += 1
    # 終了
    return false
  end

  # Add or remove HP command
  def command_311
    return true
  end

  # Add or remove SP command
  def command_312
    return true
  end

  # Add or remove state command
  def command_313
    return true
  end

  # Heal command
  def command_314
    return true
  end

  # Add exp command
  def command_315
    return true
  end

  # Add level command
  def command_316
    return true
  end

  # Change stat command
  def command_317
    return true
  end

  # Skill learn/forget command
  def command_318
    return true
  end

  # Equip command
  def command_319
    return true
  end

  # Name change command
  def command_320
    # アクターを取得
    actor = $game_actors[@parameters[0]]
    actor.name = @parameters[1] if actor
    # 継続
    return true
  end

  # Class change command
  def command_321
    return true
  end

  # Actor graphic change command
  def command_322
    # アクターを取得
    actor = $game_actors[@parameters[0]]
    actor&.set_graphic(@parameters[1], @parameters[2], @parameters[3], @parameters[4])
    # プレイヤーをリフレッシュ
    $game_player.refresh
    # 継続
    return true
  end
end
