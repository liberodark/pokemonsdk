module Battle
  module Effects
    # Implement the Miracle Eye effect
    class MiracleEye < PokemonTiedEffectBase
      # Create a new Pokemon Foresight effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :miracle_eye
      end
    end
  end
end
