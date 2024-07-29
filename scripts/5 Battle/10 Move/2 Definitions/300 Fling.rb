module Battle
  class Move
    # Power and effects depends on held item.
    class Fling < Basic
      include Mechanics::PowerBasedOnItem

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless @thrown_item_effect.respond_to?(:apply_common_effects_with_fling)

          @thrown_item_effect.apply_common_effects_with_fling(scene, target, user, self)
        end
      ensure
        @thrown_item_effect = nil
      end

      # Tell if the item is consumed during the attack
      # @return [Boolean]
      def consume_item?
        return true
      end

      # Test if the held item is valid
      # @param name [Symbol]
      # @return [Boolean]
      def valid_held_item?(name)
        return (data_item(name).fling_power || 0) > 0
      end

      # Get the real power of the move depending on the item
      # @param name [Symbol]
      # @return [Integer]
      def get_power_by_item(name)
        return data_item(name).fling_power || 0
      end
    end

    Move.register(:s_fling, Fling)
  end
end
