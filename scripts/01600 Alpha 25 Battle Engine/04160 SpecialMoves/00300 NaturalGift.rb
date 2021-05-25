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
        NATURAL_GIFT_TABLE[name][1]
      end

      # Table of the move caracteristics depending on the held item. item_db_symbol => [power, type]
      # @return [Hash<Symbol, Array<Integer, Array<Integer>>>]
      NATURAL_GIFT_TABLE = {
        :chilan_berry => [60,  [GameData::Types::NORMAL]],

        :cheri_berry => [60,  [GameData::Types::FIRE]],
        :occa_berry => [60,  [GameData::Types::FIRE]],
        :bluk_berry => [70,  [GameData::Types::FIRE]],
        :watmel_berry => [80,  [GameData::Types::FIRE]],

        :chesto_berry => [60,  [GameData::Types::WATER]],
        :passho_berry => [60,  [GameData::Types::WATER]],
        :nanab_berry => [70,  [GameData::Types::WATER]],
        :durin_berry => [80,  [GameData::Types::WATER]],

        :pecha_berry => [60,  [GameData::Types::ELECTRIC]],
        :wacan_berry => [60,  [GameData::Types::ELECTRIC]],
        :wepear_berry => [70,  [GameData::Types::ELECTRIC]],
        :belue_berry => [80,  [GameData::Types::ELECTRIC]],

        :rawst_berry => [60,  [GameData::Types::GRASS]],
        :rindo_berry => [60,  [GameData::Types::GRASS]],
        :pinap_berry => [70,  [GameData::Types::GRASS]],
        :liechi_berry => [80,  [GameData::Types::GRASS]],

        :aspear_berry => [60,  [GameData::Types::ICE]],
        :yache_berry => [60,  [GameData::Types::ICE]],
        :pomeg_berry => [70,  [GameData::Types::ICE]],
        :ganlon_berry => [80,  [GameData::Types::ICE]],

        :leppa_berry => [60,  [GameData::Types::FIGHTING]],
        :chople_berry => [60,  [GameData::Types::FIGHTING]],
        :kelpsy_berry => [70,  [GameData::Types::FIGHTING]],
        :salac_berry => [80,  [GameData::Types::FIGHTING]],

        :oran_berry => [60,  [GameData::Types::POISON]],
        :kebia_berry => [60,  [GameData::Types::POISON]],
        :qualot_berry => [70,  [GameData::Types::POISON]],
        :petaya_berry => [80,  [GameData::Types::POISON]],

        :persim_berry => [60,  [GameData::Types::GROUND]],
        :shuca_berry => [60,  [GameData::Types::GROUND]],
        :hondew_berry => [70,  [GameData::Types::GROUND]],
        :apicot_berry => [80,  [GameData::Types::GROUND]],

        :lum_berry => [60,  [GameData::Types::FLYING]],
        :coba_berry => [60,  [GameData::Types::FLYING]],
        :grepa_berry => [70,  [GameData::Types::FLYING]],
        :lansat_berry => [80,  [GameData::Types::FLYING]],

        :sitrus_berry => [60,  [GameData::Types::PSYCHIC]],
        :payapa_berry => [60,  [GameData::Types::PSYCHIC]],
        :tamato_berry => [70,  [GameData::Types::PSYCHIC]],
        :starf_berry => [80,  [GameData::Types::PSYCHIC]],

        :figy_berry => [60,  [GameData::Types::BUG]],
        :tanga_berry => [60,  [GameData::Types::BUG]],
        :cornn_berry => [70,  [GameData::Types::BUG]],
        :enigma_berry => [80,  [GameData::Types::BUG]],

        :wiki_berry => [60,  [GameData::Types::ROCK]],
        :charti_berry => [60,  [GameData::Types::ROCK]],
        :magost_berry => [70,  [GameData::Types::ROCK]],
        :micle_berry => [80,  [GameData::Types::ROCK]],

        :mago_berry => [60,  [GameData::Types::GHOST]],
        :kasib_berry => [60,  [GameData::Types::GHOST]],
        :rabuta_berry => [70,  [GameData::Types::GHOST]],
        :custap_berry => [80,  [GameData::Types::GHOST]],

        :aguav_berry => [60,  [GameData::Types::DRAGON]],
        :haban_berry => [60,  [GameData::Types::DRAGON]],
        :nomel_berry => [70,  [GameData::Types::DRAGON]],
        :jaboca_berry => [80,  [GameData::Types::DRAGON]],
       
        :iapapa_berry => [60,  [GameData::Types::DARK]],
        :colbur_berry => [60,  [GameData::Types::DARK]],
        :spelon_berry => [70,  [GameData::Types::DARK]],
        :rowap_berry => [80,  [GameData::Types::DARK]],
        
        :razz_berry => [60,  [GameData::Types::STEEL]],
        :babiri_berry => [60,  [GameData::Types::STEEL]],
        :pamtre_berry => [70,  [GameData::Types::STEEL]]
      }
    end
    Move.register(:s_natural_gift, NaturalGift)
  end
end