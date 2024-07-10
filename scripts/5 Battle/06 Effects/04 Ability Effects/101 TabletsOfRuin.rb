module Battle
  module Effects
    class TabletsOfRuin < EffectBase
      # Give the atk modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def atk_modifier
        return 0.75
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :tablets_of_ruin
      end
    end

    class BeadsOfRuin < EffectBase
      # Give the dfs modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def dfs_modifier
        return @logic.terrain_effects.has?(:wonder_room) ? super : 0.75
      end

      # Give the dfe modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def dfe_modifier
        return @logic.terrain_effects.has?(:wonder_room) ? 0.75 : super
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :beads_of_ruin
      end
    end

    class VesselOfRuin < EffectBase
      # Give the ats modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def ats_modifier
        return 0.75
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :vessel_of_ruin
      end
    end

    class SwordOfRuin < EffectBase
      # Give the dfs modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def dfs_modifier
        return @logic.terrain_effects.has?(:wonder_room) ? 0.75 : super
      end

      # Give the dfe modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def dfe_modifier
        return @logic.terrain_effects.has?(:wonder_room) ? super : 0.75
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :sword_of_ruin
      end
    end
  end
end