module Battle
  module Effects
    # Implement the ability suppression (Gastro Acid)
    class AbilitySuppressed < PokemonTiedEffectBase
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :ability_suppressed
      end
    end
  end
end
