module Battle
  class Move
    # List of accuracy items modifier
    ACCURACY_ITEM_MULTIPLIER = Hash.new(:calc_item_no_multiplier)
    # List of evasion item modifier
    EVASION_ITEM_MULTIPLIER = Hash.new(:calc_item_no_multiplier)
    # List of accuracy ability modifier
    ACCURACY_ABILITY_MULTIPLIER = Hash.new(:calc_item_no_multiplier)
    # List of evasion ability modifier
    EVASION_ABILITY_MULTIPLIER = Hash.new(:calc_item_no_multiplier)
    # @return [Float] Modifier of Gravity
    GRAVITY_MODIFIER = 5.0 / 3

    # Return the chance of hit of the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Float]
    def chance_of_hit(user, target)
      log_data("# chance_of_hit(#{user}, #{target}) for #{db_symbol}")
      return 100 if target.effects.get(:lock_on)&.origin == user
      return 100 if user.has_ability?(:no_guard) || target.has_ability?(:no_guard)

      acc_mod = target.has_ability?(:unaware) && !UNAWARE_IGNORING_ABILITIES.include?(user.battle_ability_db_symbol)
      eva_mod = user.has_ability?(:unaware)
      factors = [
        acc_mod ? accuracy_mod(user) : 1,
        eva_mod ? evasion_mod(target) : 1,
        send(ACCURACY_ITEM_MULTIPLIER[user.battle_item_db_symbol], user, target),
        send(EVASION_ITEM_MULTIPLIER[target.battle_item_db_symbol], user, target),
        send(ACCURACY_ABILITY_MULTIPLIER[user.battle_ability_db_symbol], user, target),
        send(EVASION_ABILITY_MULTIPLIER[target.battle_ability_db_symbol], user, target),
        (logic.terrain_effects.has?(:gravity) ? GRAVITY_MODIFIER : 1),
        (logic.allies_of(user).any? { |ally| ally.has_ability?(:victory_star) } ? VAL_1_1 : 1)
      ]
      log_data("factors = [#{factors.join(', ')}] # acc, eva, aci, evi, aca, evaa, gr, vstar") if debug?
      log_data("result = #{factors.reduce(100, :*)}") if debug?
      return factors.reduce(100, :*)
    end

    private

    # Return the accuracy modifier of the user
    # @param user [PFM::PokemonBattler]
    # @return [Float]
    def accuracy_mod(user)
      return user.stat_multiplier_acceva(user.acc_stage)
    end

    # Return the evasion modifier of the target
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def evasion_mod(target)
      return target.stat_multiplier_acceva(-target.eva_stage) # <=> 1 / ...
    end

    # Return the acc mod of the wide lens
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def acc_mod_wide_lens(user, target)
      return VAL_1_1
    end

    # Return the acc mod of the zoom lens
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def acc_mod_zoom_lens(user, target)
      return user.order > target.order ? VAL_1_1 : 0
    end

    # Return the acc mod of compoundeyes
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def acc_mod_compoundeyes(user, target)
      return VAL_1_3
    end

    # Return the acc mod of hustle
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def acc_mod_hustle(user, target)
      return physical? ? VAL_0_8 : 1
    end

    # Return the acc mod of hustle
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def acc_mod_victory_star(user, target)
      return VAL_1_1
    end

    # Return the eva mod of wonder skin
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def eva_mod_wonder_skin(user, target)
      return status? && user.can_be_lowered_or_canceled? ? VAL_0_5 : 1
    end

    # Return the eva mod of the brightpowder
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def eva_mod_brightpowder(user, target)
      return VAL_0_9
    end

    # Return the eva mod of the lax_incense
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def eva_mod_lax_incense(user, target)
      return VAL_0_9
    end

    # Return the eva mod of sand veil
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def eva_mod_sand_veil(user, target)
      return $env.sandstorm? && user.can_be_lowered_or_canceled? ? VAL_0_8 : 1
    end

    # Return the eva mod of snow cloak
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def eva_mod_snow_cloak(user, target)
      return $env.hail? && user.can_be_lowered_or_canceled? ? VAL_0_8 : 1
    end

    # Return the eva mod of the tangled feet
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Float]
    def eva_mod_tangled_feet(user, target)
      return target.confused? && user.can_be_lowered_or_canceled? ? VAL_0_5 : 1
    end

    class << self
      # Define an ability that modifies accuracy
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_ability_accuracy_modifier(db_symbol, method_sym)
        ACCURACY_ABILITY_MULTIPLIER[db_symbol] = method_sym
      end

      # Define an ability that modifies evasion
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_ability_evasion_modifier(db_symbol, method_sym)
        EVASION_ABILITY_MULTIPLIER[db_symbol] = method_sym
      end

      # Define an item that modifies accuracy
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_item_accuracy_modifier(db_symbol, method_sym)
        ACCURACY_ITEM_MULTIPLIER[db_symbol] = method_sym
      end

      # Define an item that modifies evasion
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_item_evasion_modifier(db_symbol, method_sym)
        EVASION_ITEM_MULTIPLIER[db_symbol] = method_sym
      end
    end

    define_ability_accuracy_modifier(:compoundeyes, :acc_mod_compoundeyes)
    define_ability_accuracy_modifier(:hustle, :acc_mod_hustle)
    define_ability_accuracy_modifier(:victory_star, :acc_mod_victory_star)
    define_ability_evasion_modifier(:wonder_skin, :eva_mod_wonder_skin)
    define_ability_evasion_modifier(:sand_veil, :eva_mod_sand_veil)
    define_ability_evasion_modifier(:snow_cloak, :eva_mod_snow_cloak)
    define_ability_evasion_modifier(:tangled_feet, :eva_mod_tangled_feet)
    define_item_accuracy_modifier(:wide_lens, :acc_mod_wide_lens)
    define_item_accuracy_modifier(:zoom_lens, :acc_mod_zoom_lens)
    define_item_evasion_modifier(:brightpowder, :eva_mod_brightpowder)
    define_item_evasion_modifier(:lax_incense, :eva_mod_lax_incense)
  end
end
