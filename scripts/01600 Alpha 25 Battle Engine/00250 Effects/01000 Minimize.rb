module Battle
  module Effects
    # Implement the Minimize effect
    class Minimize < PokemonTiedEffectBase
      # Create a new Pokemon Minimize effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :minimize
      end
    end
  end
end
