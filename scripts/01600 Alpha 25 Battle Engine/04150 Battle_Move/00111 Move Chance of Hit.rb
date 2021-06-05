module Battle
  class Move
    # List of accuracy items modifier
    ACCURACY_ITEM_MULTIPLIER = Hash.new(:calc_item_no_multiplier)
    # List of evasion item modifier
    EVASION_ITEM_MULTIPLIER = Hash.new(:calc_item_no_multiplier)

    # Return the chance of hit of the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Float]
    def chance_of_hit(user, target)
      log_data("# chance_of_hit(#{user}, #{target}) for #{db_symbol}")
      return 100 if user.effects.get(:lock_on)&.target == target
      return 100 if user.has_ability?(:no_guard) || target.has_ability?(:no_guard)

      factor = logic.each_effects(user, target).reduce(1) { |product, e| product * e.chance_of_hit_multiplier(user, target, self) }
      factors = [
        factor,
        accuracy_mod(user),
        evasion_mod(target),
        send(ACCURACY_ITEM_MULTIPLIER[user.battle_item_db_symbol], user, target),
        send(EVASION_ITEM_MULTIPLIER[target.battle_item_db_symbol], user, target)
      ]
      log_data("factors = [#{factors.join(', ')}] # acc, eva, aci, evi, aca, evaa, gr, vstar") if debug?
      log_data("result = #{factors.reduce(100, :*)}") if debug?
      return factors.reduce(100, :*)
    end

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

    private

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

    class << self
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

    define_item_accuracy_modifier(:wide_lens, :acc_mod_wide_lens)
    define_item_accuracy_modifier(:zoom_lens, :acc_mod_zoom_lens)
    define_item_evasion_modifier(:brightpowder, :eva_mod_brightpowder)
    define_item_evasion_modifier(:lax_incense, :eva_mod_lax_incense)
  end
end
