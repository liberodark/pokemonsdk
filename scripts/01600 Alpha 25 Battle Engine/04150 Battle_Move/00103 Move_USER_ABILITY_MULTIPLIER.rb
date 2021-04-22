module Battle
  class Move
    # List of user ability multiplier
    USER_ABILITY_MULTIPLIER = Hash.new(:calc_ua_1)
    # List of ability that power specific move types when the user only has 1/3 (rounded down) of its HP
    POWERING_TYPE_USER_ABILITY = {}

    private

    # Default user ability multiplier (1)
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_1(user, target)
      1
    end

    # Calculate the rate of pixilate / refrigerate / aerilate
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_pixilate(user, target)
      return type_normal? ? 1.3 : 1
    end

    # Rivalry user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_rivalry(user, target)
      return 1 if (user.gender * target.gender) == 0
      return 1.25 if user.gender == target.gender
      return 0.75
    end

    # Reckless user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_reckless(user, target)
      recoil? ? 1.2 : 1
    end

    # Iron Fist user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_iron_fist(user, target)
      punching? ? 1.2 : 1
    end

    # Technicien user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_technician(user, target)
      power <= 60 ? 1.5 : 1
    end

    # Type on 1/3 hp user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_type_1_3(user, target)
      return 1 if user.hp > user.max_hp / 3
      return 1.5 if POWERING_TYPE_USER_ABILITY[user.battle_ability_db_symbol] == type

      return 1
    end

    # Dragon's Maw user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_dragons_maw(user, target)
      type_dragon? ? 1.5 : 1
    end

    # Steelworker user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_steelworker(user, target)
      type_steel? ? 1.5 : 1
    end

    # Tough Claws ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_tough_claws(user, target)
      direct? ? 1.3 : 1
    end

    # Transitor ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_transitor(user, target)
      type_electric? ? 1.5 : 1
    end

    # Punk Rock ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_punk_rock(user, target)
      sound_attack? ? 1.3 : 1
    end

    # Defeatist multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_defeatist(user, target)
      return 0.5 if user.hp < user.max_hp / 2

      return 1
    end

    # Steely Spirit ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_steely_spirit(user, target)
      return 1.5 if type_steel? && user.has_ability?(:steely_spirit)
      # Try all the adjacent partner
      return 1.5 if logic.adjacent_allies_of(user).any? { |partner| partner&.has_ability?(:steely_spirit) }
      # No partner with the right ability => 1
      return 1
    end

    # Fairy Aura, Dark Aura and Aura Break multipliers
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_auras(user, target)
      fairy_aura_active = type_fairy? && logic.any_field_ability_active?(:fairy_aura)
      dark_aura_active = type_dark? && logic.any_field_ability_active?(:dark_aura)

      return 1 unless fairy_aura_active || dark_aura_active

      return logic.any_field_ability_active?(:aura_break) ? 0.75 : 1.33
    end

    # Analytic ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_analytic(user, target)
      return VAL_1_3 if logic.battler_attacks_last?(user)

      return 1
    end

    # Power Spot ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_power_spot(user, target)
      # Try all the adjacent partner
      return 1.2 if logic.adjacent_allies_of(user).any? { |partner| partner&.has_ability?(:power_spot) }
      # No partner with the right ability => 1
      return 1
    end

    class << self
      # Define a user ability that powers a type of move in bad condition (1/3 of hp remaining)
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param type [Integer] type of the move that should be powered (x1.5)
      def define_boosting_type_ability(db_symbol, type)
        POWERING_TYPE_USER_ABILITY[db_symbol] = type
        USER_ABILITY_MULTIPLIER[db_symbol] = :calc_ua_type_1_3
      end

      # Define a user ability that power a move on certain conditions
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to use
      def define_boosting_ability(db_symbol, method_sym)
        USER_ABILITY_MULTIPLIER[db_symbol] = method_sym
      end
    end

    define_boosting_type_ability(:blaze, GameData::Types::FIRE)
    define_boosting_type_ability(:overgrow, GameData::Types::GRASS)
    define_boosting_type_ability(:torrent, GameData::Types::WATER)
    define_boosting_type_ability(:swarm, GameData::Types::BUG)
    define_boosting_ability(:rivalry, :calc_ua_rivalry)
    define_boosting_ability(:reckless, :calc_ua_reckless)
    define_boosting_ability(:iron_fist, :calc_ua_iron_fist)
    define_boosting_ability(:technician, :calc_ua_technician)
    define_boosting_ability(:pixilate, :calc_ua_pixilate)
    define_boosting_ability(:refrigerate, :calc_ua_pixilate)
    define_boosting_ability(:aerilate, :calc_ua_pixilate)
    define_boosting_ability(:galvanize, :calc_ua_pixilate)
    define_boosting_ability(:"dragon's maw", :calc_ua_dragons_maw)
    define_boosting_ability(:steelworker, :calc_ua_steelworker)
    define_boosting_ability(:punk_rock, :calc_ua_punk_rock)
    define_boosting_ability(:tough_claws, :calc_ua_tough_claws)
    define_boosting_ability(:transitor, :calc_ua_transitor)
    define_boosting_ability(:defeatist, :calc_ua_defeatist)
    define_boosting_ability(:steely_spirit, :calc_ua_steely_spirit)
    define_boosting_ability(:power_spot, :calc_ua_power_spot)
    define_boosting_ability(:fairy_aura, :calc_ua_auras)
    define_boosting_ability(:dark_aura, :calc_ua_auras)
    define_boosting_ability(:aura_break, :calc_ua_auras)
    define_boosting_ability(:analytic, :calc_ua_analytic)
  end
end
