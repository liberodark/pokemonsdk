module Battle
  class Move
    # Type depends on the Arceus Plate being held.
    # @see https://pokemondb.net/move/judgment
    # @see https://bulbapedia.bulbagarden.net/wiki/Judgment_(move)
    # @see https://www.pokepedia.fr/Jugement
    class Judgment < Basic
      include Mechanics::TypesBasedOnItem
      private

      # Tell if the item is consumed during the attack
      # @return [Boolean]
      def consume_item?
        false
      end

      # Test if the held item is valid
      # @param name [Symbol]
      # @return [Boolean]
      def valid_held_item?(name)
        return true
      end

      # Get the real types of the move depending on the item, type of the corresponding item if a plate, normal otherwise
      # @param name [Symbol]
      # @return [Array<Integer>]
      def get_types_by_item(name)
        if JUDGMENT_TABLE.keys.include?(name)
          [data_type(JUDGMENT_TABLE[name]).id]
        else
          [data_type(:normal).id]
        end
      end

      # Table of move type depending on item
      # @return [Hash<Symbol, Symbol>]
      JUDGMENT_TABLE = {
        flame_plate: :fire,
        splash_plate: :water,
        zap_plate: :electric,
        meadow_plate: :grass,
        icicle_plate: :ice,
        fist_plate: :fighting,
        toxic_plate: :poison,
        earth_plate: :ground,
        sky_plate: :flying,
        mind_plate: :psychic,
        insect_plate: :bug,
        stone_plate: :rock,
        spooky_plate: :ghost,
        draco_plate: :dragon,
        iron_plate: :steel,
        dread_plate: :dark,
        pixie_plate: :fairy
      }
    end
    Move.register(:s_judgment, Judgment)
  end
end
