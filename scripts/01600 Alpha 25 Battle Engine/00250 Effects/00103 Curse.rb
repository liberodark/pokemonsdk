module Battle
  module Effects
    # Implement the Curse effect
    class Curse < PokemonTiedEffectBase
      # Create a new Pokemon Curse effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :curse
      end
    end
  end
end
