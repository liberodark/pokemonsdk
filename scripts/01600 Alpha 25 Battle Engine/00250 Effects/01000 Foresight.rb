module Battle
  module Effects
    # Implement the Foresight effect
    # Foresight - Odor Sleuth
    class Foresight < PokemonTiedEffectBase
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :foresight
      end
    end
  end
end
