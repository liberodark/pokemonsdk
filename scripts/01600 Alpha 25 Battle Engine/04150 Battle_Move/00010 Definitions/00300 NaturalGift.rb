module Battle
  class Move
    # Natural Gift deals damage with no additional effects. However, its type and base power vary depending on the user's held Berry. 
    # @see https://pokemondb.net/move/natural-gift
    # @see https://bulbapedia.bulbagarden.net/wiki/Natural_Gift_(move)
    # @see https://www.pokepedia.fr/Don_Naturel
    class NaturalGift < Basic
      include Mechanics::PowerBasedOnItem
      include Mechanics::TypesBasedOnItem

      private

      # Tell if the item is consumed during the attack
      # @return [Boolean]
      def consume_item?
        true
      end

      # Test if the held item is valid
      # @param name [Symbol]
      # @return [Boolean]
      def valid_held_item?(name)
        NATURAL_GIFT_TABLE.keys.include?(name)
      end

      # Get the real power of the move depending on the item
      # @param name [Symbol]
      # @return [Integer]
      def get_power_by_item(name)
        NATURAL_GIFT_TABLE[name][0]
      end

      # Get the real types of the move depending on the item
      # @param name [Symbol]
      # @return [Array<Integer>]
      def get_types_by_item(name)
        [data_type(NATURAL_GIFT_TABLE[name][1]).id]
      end

      class << self
        def reset
          const_set(:NATURAL_GIFT_TABLE, {})
        end

        def register(berry, power, type)
          NATURAL_GIFT_TABLE[berry] ||= []
          NATURAL_GIFT_TABLE[berry] = [power, type]
        end
      end

      reset
      register(:chilan_berry, 80, :normal)

      register(:cheri_berry, 80, :fire)
      register(:occa_berry, 80, :fire)
      register(:bluk_berry, 90, :fire)
      register(:watmel_berry, 100, :fire)

      register(:chesto_berry, 80, :water)
      register(:passho_berry, 80, :water)
      register(:nanab_berry, 90, :water)
      register(:durin_berry, 100, :water)

      register(:pecha_berry, 80, :electric)
      register(:wacan_berry, 80, :electric)
      register(:wepear_berry, 90, :electric)
      register(:belue_berry, 100, :electric)

      register(:rawst_berry, 80, :grass)
      register(:rindo_berry, 80, :grass)
      register(:pinap_berry, 90, :grass)
      register(:liechi_berry, 100, :grass)

      register(:aspear_berry, 80, :ice)
      register(:yache_berry, 80, :ice)
      register(:pomeg_berry, 90, :ice)
      register(:ganlon_berry, 100, :ice)

      register(:leppa_berry, 80, :fighting)
      register(:chople_berry, 80, :fighting)
      register(:kelpsy_berry, 90, :fighting)
      register(:salac_berry, 100, :fighting)

      register(:oran_berry, 80, :poison)
      register(:kebia_berry, 80, :poison)
      register(:qualot_berry, 90, :poison)
      register(:petaya_berry, 100, :poison)

      register(:persim_berry, 80, :ground)
      register(:shuca_berry, 80, :ground)
      register(:hondew_berry, 90, :ground)
      register(:apicot_berry, 100, :ground)

      register(:lum_berry, 80, :flying)
      register(:coba_berry, 80, :flying)
      register(:grepa_berry, 90, :flying)
      register(:lansat_berry, 100, :flying)

      register(:sitrus_berry, 80, :psychic)
      register(:payapa_berry, 80, :psychic)
      register(:tamato_berry, 90, :psychic)
      register(:starf_berry, 100, :psychic)

      register(:figy_berry, 80, :bug)
      register(:tanga_berry, 80, :bug)
      register(:cornn_berry, 90, :bug)
      register(:enigma_berry, 100, :bug)

      register(:wiki_berry, 80, :rock)
      register(:charti_berry, 80, :rock)
      register(:magost_berry, 90, :rock)
      register(:micle_berry, 100, :rock)

      register(:mago_berry, 80, :ghost)
      register(:kasib_berry, 80, :ghost)
      register(:rabuta_berry, 90, :ghost)
      register(:custap_berry, 100, :ghost)

      register(:aguav_berry, 80, :dragon)
      register(:haban_berry, 80, :dragon)
      register(:nomel_berry, 90, :dragon)
      register(:jaboca_berry, 100, :dragon)

      register(:iapapa_berry, 80, :dark)
      register(:colbur_berry, 80, :dark)
      register(:spelon_berry, 90, :dark)
      register(:rowap_berry, 100, :dark)

      register(:razz_berry, 80, :steel)
      register(:babiri_berry, 80, :steel)
      register(:pamtre_berry, 90, :steel)

      register(:roseli_berry, 80, :fairy)
      register(:kee_berry, 100, :fairy)

      register(:maranga_berry, 100, :dark)
    end
    Move.register(:s_natural_gift, NaturalGift)
  end
end
