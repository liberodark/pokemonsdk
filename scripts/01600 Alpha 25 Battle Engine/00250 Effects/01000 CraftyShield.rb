module Battle
  module Effects
    # Implement Crafty Shield effect that protects Pokemon from status moves
    class CraftyShield < PokemonTiedEffectBase
      # Create a new CraftyShield effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :crafty_shield
      end
    end
  end
end
