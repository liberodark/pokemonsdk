module Battle
  class Move
    # List of ability multiplier for the foe
    FOE_ABILITY_MULTIPLIER = Hash.new(:calc_ua_1)
    # Types required by thick fat to trigger the multiplier
    THICK_FAT_TYPES = [GameData::Types::FIRE, GameData::Types::ICE]

    private

    # Thick Fat foe ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_thick_fat(user, target)
      THICK_FAT_TYPES.include?(type) ? VAL_0_5 : 1
    end

    # Heatproof foe ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_heatproof(user, target)
      type == GameData::Types::FIRE ? VAL_0_5 : 1
    end

    # Dry Skin foe ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_dry_skin(user, target)
      type == GameData::Types::FIRE ? 1.25 : 1
    end

    class << self
      # Define an ability of the foe that deplete the move power
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] symbol of the method to use
      def define_depleting_ability(db_symbol, method_sym)
        FOE_ABILITY_MULTIPLIER[db_symbol] = method_sym
      end
    end

    define_depleting_ability(:thick_fat, :calc_fa_thick_fat)
    define_depleting_ability(:heatproof, :calc_fa_heatproof)
    define_depleting_ability(:dry_skin, :calc_fa_dry_skin)
  end
end
