#encoding: utf-8

class Interpreter_RMXP
  # Enemy HP change command
  def command_331
    return true
  end

  # Enemy SP change command
  def command_332
    return true
  end

  # Enemy state change command
  def command_333
    return true
  end

  # Enemy heal command
  def command_334
    return true
  end

  # Enemy show command
  def command_335
    return true
  end

  # Enemy transform command
  def command_336
    return true
  end

  # Play animation on battler
  def command_337
    return true
  end

  # Damage on battler command
  def command_338
    return true
  end

  # Battler force action command
  def command_339
    return true
  end

  # End battle command
  def command_340
    @index += 1
    return false
  end

  # Call menu command
  def command_351
    # バトル中断フラグをセット
    $game_temp.battle_abort = true
    # メニュー呼び出しフラグをセット
    $game_temp.menu_calling = true
    # インデックスを進める
    @index += 1
    # 終了
    return false
  end

  # Call save command
  def command_352
    # バトル中断フラグをセット
    $game_temp.battle_abort = true
    # セーブ呼び出しフラグをセット
    $game_temp.save_calling = true
    # インデックスを進める
    @index += 1
    # 終了
    return false
  end

  # Game Over command
  def command_353
    # ゲームオーバーフラグをセット
    $game_temp.gameover = true
    # 終了
    return false
  end

  # Go to title command
  def command_354
    # タイトル画面に戻すフラグをセット
    $game_temp.to_title = true
    # 終了
    return false
  end

  # Execute script command
  def command_355
    # script に 1 行目を設定
    script = @list[@index].parameters[0] + "\n"
    # ループ
    loop do
      # 次のイベントコマンドがスクリプト 2 行目以降の場合
      if @list[@index+1].code == 655
        # script に 2 行目以降を追加
        script += @list[@index+1].parameters[0] + "\n"
      # イベントコマンドがスクリプト 2 行目以降ではない場合
      else
        # ループ中断
        break
      end
      # インデックスを進める
      @index += 1
    end
    # 評価
    eval_script(script)
    return true
  end

  # Function that execute a script
  # @param script [String]
  def eval_script(script)
    last_eval = Yuki::EXC.get_eval_script
    script = script.force_encoding('UTF-8').gsub(/\n([(,])/, "\\1\n")
    Yuki::EXC.set_eval_script(script)
    eval(script)
  rescue StandardError => e
    Yuki::EXC.run(e)
    $scene = nil # It's better to close the game in that case
  ensure
    Yuki::EXC.set_eval_script(last_eval)
  end
end
