module Battle
  class Move
    class IvyCudgel < Basic
      include Mechanics::TypesBasedOnItem

      # Tell if the item is consumed during the attack
      # @return [Boolean]
      def consume_item?
        return false
      end

      # Test if the held item is valid
      # @param name [Symbol]
      # @return [Boolean]
      def valid_held_item?(name)
        return true
      end

      # Get the real types of the move depending on the item, type of the corresponding item if a mask, normal otherwise
      # @param name [Symbol]
      # @return [Array<Integer>]
      def get_types_by_item(name)
        if IVYCUDGEL_TABLE.keys.include?(name)
          [data_type(IVYCUDGEL_TABLE[name]).id]
        else
          [data_type(:grass).id]
        end
      end

      # Table of move type depending on item
      # @return [Hash<Symbol, Symbol>]
      IVYCUDGEL_TABLE = {
        wellspring_mask: :water,
        hearthflame_mask: :fire,
        cornerstone_mask: :rock
      }
    end
    Move.register(:s_ivy_cudgel, IvyCudgel)
  end
end
