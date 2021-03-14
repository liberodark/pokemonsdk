module Battle
  module Effects
    # Implement the Miracle Eye effect
    class MiracleEye < PokemonTiedEffectBase
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :miracle_eye
      end
    end
  end
end
