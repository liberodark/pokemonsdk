# The RPG Maker description of a Party
class Game_Party
  attr_reader :actors

  attr_accessor :gold

  attr_accessor :steps

  # Default initialization
  def initialize
    # アクターの配列を作成
    @actors = []
    # ゴールドと歩数を初期化
    @gold = 0
    @steps = 0
    # アイテム、武器、防具の所持数ハッシュを作成
    @items = {}
    @weapons = {}
    @armors = {}
  end

  # Set up the party with default members
  def setup_starting_members
    @actors = []
    log_info("Initial party members : #{$data_system.party_members}")
    for i in $data_system.party_members
      @actors.push($game_actors[i])
    end
  end

  # Refresh the game party with right actors according to the RMXP data
  def refresh
    # ゲームデータをロードした直後はアクターオブジェクトが
    # $game_actors から分離してしまっている。
    # ロードのたびにアクターを再設定することで問題を回避する。
    new_actors = []
    for i in 0...@actors.size
      if $data_actors[@actors[i].id] != nil
        new_actors.push($game_actors[@actors[i].id])
      end
    end
    @actors = new_actors
  end

  # Returns the max level in the team
  # @return [Integer] 0 if no actors
  def max_level
    return 1
  end

  # Add an actor to the party
  # @param actor_id [Integer] the id of the actor in the database
  def add_actor(actor_id)
    # アクターを取得
    actor = $game_actors[actor_id]
    # パーティ人数が 4 人未満で、このアクターがパーティにいない場合
    if @actors.size < 4 and not @actors.include?(actor)
      # アクターを追加
      @actors.push(actor)
      # プレイヤーをリフレッシュ
      $game_player.refresh
    end
  end

  # Remove an actor of the party
  # @param actor_id [Integer] the id of the actor in the database
  def remove_actor(actor_id)
    # アクターを削除
    @actors.delete($game_actors[actor_id])
    # プレイヤーをリフレッシュ
    $game_player.refresh
  end

  # gives gold to the party
  # @param n [Integer] amount of gold
  def gain_gold(n)
    @gold = [[@gold + n, 0].max, 9999999].min
  end

  # takes gold from the party
  # @param n [Integer] amount of gold
  def lose_gold(n)
    # 数値を逆転して gain_gold を呼ぶ
    gain_gold(-n)
  end

  # Increase steps of the party
  def increase_steps
    @steps = [@steps + 1, 9999999].min
  end
end
