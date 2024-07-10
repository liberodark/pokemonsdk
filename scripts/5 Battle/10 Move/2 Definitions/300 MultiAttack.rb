module Battle
  class Move
    # Type depends on the Sylvally ROM being held.
    # @see https://pokemondb.net/move/judgment
    # @see https://bulbapedia.bulbagarden.net/wiki/Judgment_(move)
    # @see https://www.pokepedia.fr/Jugement
    class MultiAttack < Basic
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

      # Get the real types of the move depending on the item, type of the corresponding item if a memory, normal otherwise
      # @param name [Symbol]
      # @return [Array<Integer>]
      def get_types_by_item(name)
        if MEMORY_TABLE.keys.include?(name)
          [data_type(MEMORY_TABLE[name]).id]
        else
          [data_type(:normal).id]
        end
      end

      # Table of move type depending on item
      # @return [Hash<Symbol, Symbol>]
      MEMORY_TABLE = {
        fire_memory: :fire,
        water_memory: :water,
        electric_memory: :electric,
        grass_memory: :grass,
        ice_memory: :ice,
        fighting_memory: :fighting,
        poison_memory: :poison,
        ground_memory: :ground,
        flying_memory: :flying,
        psychic_memory: :psychic,
        bug_memory: :bug,
        rock_memory: :rock,
        ghost_memory: :ghost,
        dragon_memory: :dragon,
        steel_memory: :steel,
        dark_memory: :dark,
        fairy_memory: :fairy
      }
    end
    Move.register(:s_multi_attack, MultiAttack)
  end
end
