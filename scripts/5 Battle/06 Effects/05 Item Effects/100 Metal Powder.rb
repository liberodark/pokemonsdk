module Battle
  module Effects
    class Item
      class MetalPowder < Item
        # Give the dfe modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfe_modifier
          return 2 if @target.db_symbol == :ditto && @target.transform.nil?

          return super
        end
      end

      register(:metal_powder, MetalPowder)
    end
  end
end
