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

    # Punk Rock foe ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_punk_rock(user, target)
      sound_attack? ? VAL_0_5 : 1
    end

    # Fluffy foe ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_fluffy(user, target)
      return VAL_0_5 if direct?
      return 2 if type == GameData::Types::FIRE
      return 1
    end

    # Ice Scales ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_ice_scales
      return VAL_0_5 if special? 
      return 1
    end

    # Multiscale/Shadow Shield multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_max_hp(user, target)
      return VAL_0_5 if user.hp = user.max_hp

      return 1
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
    define_depleting_ability(:punk_rock, :calc_fa_punk_rock)
    define_depleting_ability(:fluffy, :calc_fa_fluffy)
    define_depleting_ability(:ice_scales, :calc_fa_ice_scales)
    define_depleting_ability(:multiscale, :calc_fa_max_hp)
    define_depleting_ability(:shadow_shield, :calc_fa_max_hp)
  end
end
