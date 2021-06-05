module PFM
  class PokemonBattler
    # List of item speed modifier
    SPEED_MODIFIER_ITEM = Hash.new(:calc_us_1).merge!(
      choice_scarf: :calc_us_1_5,
      iron_ball:    :calc_us_0_5,
      macho_brace:  :calc_us_0_5,
      power_anklet: :calc_us_0_5,
      power_band:   :calc_us_0_5,
      power_belt:   :calc_us_0_5,
      power_bracer: :calc_us_0_5,
      power_lens:   :calc_us_0_5,
      power_weight: :calc_us_0_5,
      quick_powder: :calc_us_quick_powder
    )
    # Constant containing 1.5
    VAL_1_5 = 1.5
    # Constant containing 0.5
    VAL_0_5 = 0.5

    private

    # Method that returns 1 as speed modifier
    # @return [Integer]
    def calc_us_1
      return 1
    end

    # Method that returns 1.5 as speed modifier
    # @return [Integer]
    def calc_us_1_5
      return VAL_1_5
    end

    # Method that returns 0.5 as speed modifier
    # @return [Integer]
    def calc_us_0_5
      return VAL_0_5
    end

    # Ditto's quick powder speed modifier
    # @return [Integer]
    def calc_us_quick_powder
      return db_symbol == :ditto ? 2 : 1
    end
  end
end
