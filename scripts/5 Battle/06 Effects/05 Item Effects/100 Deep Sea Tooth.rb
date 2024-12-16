module Battle
  module Effects
    class Item
      class DeepSeaTooth < Item
        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def ats_modifier
          return 2 if @target.db_symbol == :clamperl

          return super
        end
      end

      register(:deep_sea_tooth, DeepSeaTooth)
    end
  end
end
