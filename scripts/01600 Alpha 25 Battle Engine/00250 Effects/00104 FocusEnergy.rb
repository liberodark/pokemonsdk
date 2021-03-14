module Battle
  module Effects
    # Implement the Focus Energy effect
    class FocusEnergy < PokemonTiedEffectBase
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :focus_energy
      end
    end
  end
end
