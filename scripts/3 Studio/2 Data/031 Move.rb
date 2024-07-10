module Studio
  # Data class describing a Move
  class Move
    # ID of the move
    # @return [Integer]
    attr_reader :id

    # db_symbol of the move
    # @return [Symbol]
    attr_reader :db_symbol

    # Get the move name
    # @return [String]
    def name
      return text_get(6, @id)
    end

    # Get the move description
    # @return [String]
    def description
      return text_get(7, @id)
    end
    alias descr description

    # ID of the common event to call on map
    # @return [Integer]
    attr_reader :map_use

    # symbol that helps the battle engine to pick the right Move procedure
    # @return [Symbol]
    attr_reader :battle_engine_method
    alias be_method battle_engine_method

    # Type of the move
    # @return [Symbol]
    attr_reader :type

    # Power of the move
    # @return [Integer]
    attr_reader :power

    # Accuracy of the move
    # @return [Integer]
    attr_reader :accuracy

    # Default amount of PP of the move
    # @return [Integer]
    attr_reader :pp

    # Category of the move (:physical, :special, :status)
    # @return [Symbol]
    attr_reader :category

    # Critical rate indicator of the move (0 => 0, 1 => 6.25%, 2 => 12.5%, 3 => 25%, 4 => 33%, 5 => 50%, 6 => 100%)
    # @return [Integer]
    attr_reader :movecritical_rate
    alias critical_rate movecritical_rate

    # Priority of the move (-7 ~ 0 ~ +7)
    # @return [Integer]
    attr_reader :priority

    # If the move makes contact with opponent
    # @return [Boolean]
    attr_reader :is_direct

    # If the move has a charging turn that can be skipped with a power-herb
    # @return [Boolean]
    attr_reader :is_charge

    # If the move has a pause turn after being used
    # @return [Boolean]
    attr_reader :is_recharge

    # If the move is blocked by detect or protect
    # @return [Boolean]
    attr_reader :is_blocable

    # If the move must be stolen if another creature used Snatch during this turn
    # @return [Boolean]
    attr_reader :is_snatchable

    # Another creature can copy this move if it targets the user of this move
    # @return [Boolean]
    attr_reader :is_mirror_move

    # If this move gets a power bonus of 1.2x when user has iron-fist ability
    # @return [Boolean]
    attr_reader :is_punch

    # If this move cannot be used under gravity
    # @return [Boolean]
    attr_reader :is_gravity

    # If this move can be reflected by magic-coat move or magic-bounce ability
    # @return [Boolean]
    attr_reader :is_magic_coat_affected

    # If this move can be used while frozen and defreeze user
    # @return [Boolean]
    attr_reader :is_unfreeze

    # If target of this move with ability soundproof are immune to this move
    # @return [Boolean]
    attr_reader :is_sound_attack

    # If the move deals 1.5x damage when user has sharpness ability
    # @return [Boolean]
    attr_reader :is_slicing_attack

    # If target of this move with ability wind power or wind rider will be activated to this move
    # @return [Boolean]
    attr_reader :is_wind

    # If the move can reach any target regardless of the position
    # @return [Boolean]
    attr_reader :is_distance

    # If the move can be blocked by heal-block
    # @return [Boolean]
    attr_reader :is_heal

    # If the move ignore the target's substitute
    # @return [Boolean]
    attr_reader :is_authentic

    # If the move deals 1.5x damage when user has strong-jaw ability
    # @return [Boolean]
    attr_reader :is_bite

    # If the move deals 1.5x damage when user has mega-launcher ability
    # @return [Boolean]
    attr_reader :is_pulse

    # If this move is blocked by bulletproof ability
    # @return [Boolean]
    attr_reader :is_ballistics

    # If this move is blocked by aroma-veil ability and cured by mental-herb item
    # @return [Boolean]
    attr_reader :is_mental

    # If this move cannot be used in Sky Battles
    # @return [Boolean]
    attr_reader :is_non_sky_battle

    # If this move triggers the dancer ability
    # @return [Boolean]
    attr_reader :is_dance

    # If this move triggers the King's Rock
    # @return [Boolean]
    attr_reader :is_king_rock_utility

    # If grass-type or creatures with overcoat ability are immune to this move
    # @return [Boolean]
    attr_reader :is_powder

    # Chance to trigger the secondary effect (0~100)
    # @return [Integer]
    attr_reader :effect_chance

    # Target type the move can aim
    # @return [Symbol]
    attr_reader :battle_engine_aimed_target

    # List of stage this move change
    # @return [Array<BattleStageMod>]
    attr_reader :battle_stage_mod

    # List of status this move can apply
    # @return [Array<MoveStatus>]
    attr_reader :move_status

    # Class describing the stat modification
    class BattleStageMod
      # Stat this stage mod change (:atk, :dfe, :spd, :ats, :dfs, :eva, :acc)
      # @return [Symbol]
      attr_reader :stat

      # Amount of the stage it changes
      # @return [Integer]
      attr_reader :count
    end

    # Class describing the status modification with it's chance to happen
    class MoveStatus
      # Status this move applies
      # @return [Symbol]
      attr_reader :status

      # Chance to trigger this status (0~100)
      # @return [Integer]
      attr_reader :luck_rate
    end
  end
end
