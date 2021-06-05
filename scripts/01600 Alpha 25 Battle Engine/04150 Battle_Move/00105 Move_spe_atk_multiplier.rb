module Battle
  class Move
    def calc_ua_1(*)
      return 1
    end
    # List of atk modifier method from item
    ATK_ITEM_MODIFIER = Hash.new(:calc_ua_1)
    # List of ats modifier method from item
    ATS_ITEM_MODIFIER = Hash.new(:calc_ua_1)
    # Pokemon that can hold the thick club and get the bonus
    THICK_CLUB_POKEMON = %i[cubone marowak]
    # Ability that interact with plus & minus
    PLUS_MINUS_ABILITIES = %i[plus minus]
    # Pokemon that can hold the soul dew and get the bonus
    SOUL_DEW_POKEMON = %i[latios latias]

    private

    # Pure Power ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_am_pure_power(user, target)
      2
    end

    # Flower Gift ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_am_flower_gift(user, target)
      $env.sunny? && user.can_be_lowered_or_canceled? ? 1.5 : 1
    end
    # Choice Band item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_im_choice_band(user, target)
      1.5
    end

    # Thick Club item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_im_thick_club(user, target)
      THICK_CLUB_POKEMON.include?(user.db_symbol) ? 2 : 1
    end

    # Soul Dew item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_im_soul_dew(user, target)
      SOUL_DEW_POKEMON.include?(user.db_symbol) ? 1.5 : 1
    end

    # Deep Sea Tooth item multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_im_deep_sea_tooth(user, target)
      user.db_symbol == :clamperl ? 2 : 1
    end

    class << self
      # Define an item that modifies atk
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_item_atk_modifier(db_symbol, method_sym)
        ATK_ITEM_MODIFIER[db_symbol] = method_sym
      end

      # Define an item that modifies ats
      # @param db_symbol [Symbol] db_symbol of the ability
      # @param method_sym [Symbol] name of the method to call
      def define_item_ats_modifier(db_symbol, method_sym)
        ATS_ITEM_MODIFIER[db_symbol] = method_sym
      end
    end
    define_item_atk_modifier(:choice_band, :calc_im_choice_band)
    define_item_atk_modifier(:thick_club, :calc_im_thick_club)
    define_item_ats_modifier(:choice_specs, :calc_im_choice_band)
    define_item_ats_modifier(:soul_dew, :calc_im_soul_dew)
    define_item_ats_modifier(:deep_sea_tooth, :calc_im_deep_sea_tooth)
  end
end
