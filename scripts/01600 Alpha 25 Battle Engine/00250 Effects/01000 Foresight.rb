module Battle
  module Effects
    # Implement the Foresight effect
    # Foresight - Odor Sleuth
    class Foresight < PokemonTiedEffectBase
      # Create a new Pokemon Foresight effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :foresight
      end
    end
  end
end
