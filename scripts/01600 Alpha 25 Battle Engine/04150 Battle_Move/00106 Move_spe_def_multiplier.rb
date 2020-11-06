module Battle
  class Move
    # List of dfe modifier method from ability
    DFE_ABILITY_MODIFIER = Hash.new(:calc_ua_1)
    # List of dfs modifier method from ability
    DFS_ABILITY_MODIFIER = Hash.new(:calc_ua_1)
    # List of dfe modifier method from item
    DFE_ITEM_MODIFIER = Hash.new(:calc_ua_1)
    # List of dfs modifier method from item
    DFS_ITEM_MODIFIER = Hash.new(:calc_ua_1)

    # Metal Powder item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_def_mod_metal_powder(user, target)
      return 1 unless target.db_symbol == :ditto
      target.moveset.each do |move|
        return 1 if move.db_symbol == :transform && move.used
      end
      return 1.5
    end

    # Marvel Scale ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_def_mod_marvel_scale(user, target)
      return 1.5 if target.paralyzed? || target.poisoned? || target.toxic? || target.burn? || target.asleep? ||
                    target.frozen?
      return 1
    end

    # Deep Sea Scale item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_def_mod_deep_sea_scale(user, target)
      target.db_symbol == :clamperl ? 2 : 1
    end

    # Soul Dew item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_def_mod_soul_dew(user, target)
      SOUL_DEW_POKEMON.include?(target.db_symbol) ? 1.5 : 1
    end

    class << self
      # Define an ability that modifies dfe
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_ability_dfe_modifier(db_symbol, method_sym)
        DFE_ABILITY_MODIFIER[db_symbol] = method_sym
      end

      # Define an ability that modifies dfs
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_ability_dfs_modifier(db_symbol, method_sym)
        DFS_ABILITY_MODIFIER[db_symbol] = method_sym
      end

      # Define an item that modifies dfe
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_item_dfe_modifier(db_symbol, method_sym)
        DFE_ITEM_MODIFIER[db_symbol] = method_sym
      end

      # Define an item that modifies dfs
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_item_dfs_modifier(db_symbol, method_sym)
        DFS_ITEM_MODIFIER[db_symbol] = method_sym
      end
    end
    define_ability_dfe_modifier(:marvel_scale, :calc_def_mod_marvel_scale)
    define_ability_dfs_modifier(:flower_gift, :calc_am_flower_gift)
    define_item_dfe_modifier(:metal_powder, :calc_def_mod_metal_powder)
    define_item_dfs_modifier(:metal_powder, :calc_def_mod_metal_powder)
    define_item_dfs_modifier(:deep_sea_scale, :calc_def_mod_deep_sea_scale)
    define_item_dfs_modifier(:soul_dew, :calc_def_mod_soul_dew)
  end
end
