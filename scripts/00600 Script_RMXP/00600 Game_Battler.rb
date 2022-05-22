# @deprecated No longer used...
class Game_BattleAction
end

# @deprecated No longer used in its original use.
class Game_Battler
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :battler_name             # バトラー ファイル名
  attr_reader   :battler_hue              # バトラー 色相
  attr_reader   :hp                       # HP
  attr_reader   :sp                       # SP
  attr_reader   :states                   # ステート
  attr_accessor :hidden                   # 隠れフラグ
  attr_accessor :damage                   # ダメージ値
  attr_accessor :critical                 # クリティカルフラグ
  attr_accessor :animation_id             # アニメーション ID
  attr_accessor :animation_hit            # アニメーション ヒットフラグ
  attr_accessor :white_flash              # 白フラッシュフラグ
  attr_accessor :blink                    # 明滅フラグ
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @battler_name = nil.to_s
    @battler_hue = 0
    @hp = 0
    @sp = 0
    @states = []
    @states_turn = {}
    @hidden = false
    @damage = nil
    @critical = false
    @animation_id = 0
    @animation_hit = false
    @white_flash = false
    @blink = false
  end

  def str
    return 1
  end

  def dex
    return 1
  end

  def agi
    return 1
  end

  def int
    return 1
  end

  def hit
    return 0
  end

  def atk
    return 1
  end

  def pdef
    return 1
  end

  def mdef
    return 1
  end

  def eva
    return 1
  end

  def hp=(hp)
    @hp = hp.clamp(0, 1)
  end

  def sp=(sp)
    @sp = sp.clamp(0, 1)
  end

  def dead?
    return false
  end

  def exist?
    return true
  end
end

# @deprecated Not used by the core.
class Game_Enemy < Game_Battler
  def initialize(troop_id, member_index)
    super()
  end

  def id
    return 0
  end

  def index
    return 0
  end

  def name
    return nil.to_s
  end

  def actions
    return []
  end

  def exp
    return 1
  end

  def gold
    return 1
  end

  def item_id
    return 0
  end

  def screen_x
    return 0
  end

  def screen_y
    return 0
  end

  def screen_z
    return 0
  end
end

# Class that describe a troop of enemies
class Game_Troop
  # Default initializer.
  def initialize
    # エネミーの配列を作成
    @enemies = []
  end

  # Returns the list of enemies
  # @return [Array<Game_Enemy>]
  def enemies
    return @enemies
  end

  # Setup the troop with a troop from the database
  # @param troop_id [Integer] the id of the troop in the database
  def setup(troop_id)
    @enemies = []
  end
end

# Describe a player
class Game_Actor < Game_Battler
  attr_reader :name
  attr_reader :character_name
  attr_reader :character_hue
  attr_reader :battler_name
  attr_reader :level
  attr_reader :exp
  attr_reader :skills

  # Initialize a new Game_Actor
  # @param actor_id [Integer] the id of the actor in the database
  def initialize(actor_id)
    super()
    setup(actor_id)
  end

  # setup the Game_Actor object
  # @param actor_id [Integer] the id of the actor in the database
  def setup(actor_id)
    actor = $data_actors[actor_id]
    @actor_id = actor_id
    @name = actor.name
    @character_name = actor.character_name
    @character_hue = actor.character_hue
    @battler_name = actor.battler_name
    @battler_hue = actor.battler_hue
  end

  # id of the Game_Actor in the database
  # @return [Integer]
  def id
    return @actor_id
  end

  # index of the Game_Actor in the $game_party.
  # @return [Integer, nil]
  def index
    return $game_party.actors.index(self)
  end
  # @deprecated will be removed.
  def exp=(exp)

  end
  # @deprecated will be removed.
  def level=(level)

  end
  # sets the name of the Game_Actor
  # @param name [String] the name
  def name=(name)
    @name = name
  end

  # Update the graphics of the Game_Actor
  # @param character_name [String] name of the character in Graphics/Characters
  # @param character_hue [0] ignored by the cache
  # @param battler_name [String] name of the battler in Graphics/Battlers
  # @param battler_hue [0] ignored by the cache
  def set_graphic(character_name, character_hue, battler_name, battler_hue)
    @character_name = character_name
    @character_hue = character_hue
    @battler_name = battler_name
    @battler_hue = battler_hue
  end

  # @deprecated will be removed.
  def screen_x
    return 0
  end

  # @deprecated will be removed.
  def screen_y
    return 464
  end

  # @deprecated will be removed.
  def screen_z
    return 0
  end
end
