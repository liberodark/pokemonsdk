module Battle
  module Effects
    # Implement Crafty Shield effect that protects Pokemon from status moves
    class CraftyShield < PokemonTiedEffectBase
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :crafty_shield
      end
    end
  end
end
