module Battle
  class Move
    # List of multiplier for the items
    ITEM_MULTIPLIER = Hash.new(:calc_item_no_multiplier)
    # Type required by the adamant orb to give a boost
    ADAMANT_ORB_TYPES = [GameData::Types::DRAGON, GameData::Types::STEEL]
    # Type required by the lustrous orb to give a boost
    LUSTROUS_ORB_TYPES = [GameData::Types::DRAGON, GameData::Types::WATER]
    # Type required by the griseous orb to give a boost
    GRISEOUS_ORB_TYPES = [GameData::Types::DRAGON, GameData::Types::GHOST]
    # @return [Hash{Symbol => Integer}] list of item_db_symbol to type boosting item
    BOOSTING_TYPE_ITEMS = {}
    # Constant that contains 1.1
    VAL_1_1 = 1.1
    # Constant that contains 0.9
    VAL_0_9 = 0.9
    # Constant that contains 0.95
    VAL_0_95 = 0.95
    # Constant that contains 1.3
    VAL_1_3 = 1.3
    # Constant that contains 0.8
    VAL_0_8 = 0.8
    # Constant that contains 0.5
    VAL_0_5 = 0.5

    private

    # Default item multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_item_no_multiplier(user, target)
      1
    end

    # Calc the Muscle Band multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_muscle_band_multiplier(user, target)
      physical? ? VAL_1_1 : 1
    end

    # Calc the Wise Glasses multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_wise_glasses_multiplier(user, target)
      special? ? VAL_1_1 : 1
    end

    # Calc the Adamant Orb multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_adamant_orb_multiplier(user, target)
      return 1 unless user.db_symbol == :dialga
      return ADAMANT_ORB_TYPES.include?(type) ? 1.2 : 1
    end

    # Calc the Lustrous Orb multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_lustrous_orb_multiplier(user, target)
      return 1 unless user.db_symbol == :palkia
      return LUSTROUS_ORB_TYPES.include?(type) ? 1.2 : 1
    end

    # Calc the Griseous Orb multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_griseous_orb_multiplier(user, target)
      return 1 unless user.db_symbol == :giratina
      return GRISEOUS_ORB_TYPES.include?(type) ? 1.2 : 1
    end

    # Calc the item boost multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_item_boost_type_multiplier(user, target)
      BOOSTING_TYPE_ITEMS[user.item_db_symbol] == type ? 1.2 : 1
    end

    class << self
      # Define an item that boost the power of a move by 20% if held by any Pokemon
      # @param db_symbol [Symbol] db_symbol of the item
      # @param type [Integer] type that should be powered by this item
      def define_boosting_type_item(db_symbol, type)
        BOOSTING_TYPE_ITEMS[db_symbol] = type
        ITEM_MULTIPLIER[db_symbol] = :calc_item_boost_type_multiplier
      end

      # Define the method that will specify the multiplier of an held item
      # @param db_symbol [Symbol] db_symbol of the item
      # @param method_sym [Symbol] method used to get the multiplier
      def define_boosting_item(db_symbol, method_sym)
        ITEM_MULTIPLIER[db_symbol] = method_sym
      end
    end

    define_boosting_type_item(:sea_incense, GameData::Types::WATER)
    define_boosting_type_item(:odd_incense, GameData::Types::PSYCHIC)
    define_boosting_type_item(:rock_incense, GameData::Types::ROCK)
    define_boosting_type_item(:wave_incense, GameData::Types::WATER)
    define_boosting_type_item(:rose_incense, GameData::Types::GRASS)
    define_boosting_type_item(:flame_plate, GameData::Types::FIRE)
    define_boosting_type_item(:splash_plate, GameData::Types::WATER)
    define_boosting_type_item(:zap_plate, GameData::Types::ELECTRIC)
    define_boosting_type_item(:meadow_plate, GameData::Types::GRASS)
    define_boosting_type_item(:icicle_plate, GameData::Types::ICE)
    define_boosting_type_item(:fist_plate, GameData::Types::FIGHTING)
    define_boosting_type_item(:toxic_plate, GameData::Types::POISON)
    define_boosting_type_item(:earth_plate, GameData::Types::GROUND)
    define_boosting_type_item(:sky_plate, GameData::Types::FLYING)
    define_boosting_type_item(:mind_plate, GameData::Types::PSYCHIC)
    define_boosting_type_item(:insect_plate, GameData::Types::BUG)
    define_boosting_type_item(:stone_plate, GameData::Types::ROCK)
    define_boosting_type_item(:spooky_plate, GameData::Types::GHOST)
    define_boosting_type_item(:draco_plate, GameData::Types::DRAGON)
    define_boosting_type_item(:dread_plate, GameData::Types::DARK)
    define_boosting_type_item(:iron_plate, GameData::Types::STEEL)
    define_boosting_type_item(:pixie_plate, GameData::Types::FAIRY)
    define_boosting_item(:muscle_band, :calc_muscle_band_multiplier)
    define_boosting_item(:wise_glasses, :calc_wise_glasses_multiplier)
    define_boosting_item(:adamant_orb, :calc_adamant_orb_multiplier)
    define_boosting_item(:lustrous_orb, :calc_lustrous_orb_multiplier)
    define_boosting_item(:griseous_orb, :calc_griseous_orb_multiplier)
  end
end
