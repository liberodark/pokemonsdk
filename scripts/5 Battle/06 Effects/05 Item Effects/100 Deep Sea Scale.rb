module Battle
  module Effects
    class Item
      class DeepSeaScale < Item
        # Give the dfs modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfs_modifier
          return 2 if @target.db_symbol == :clamperl

          return super
        end
      end

      register(:deep_sea_scale, DeepSeaScale)
    end
  end
end
