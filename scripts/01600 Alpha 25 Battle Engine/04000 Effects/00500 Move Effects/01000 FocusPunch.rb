module Battle
  module Effects
    # Implement the Beak Blast effect
    class FocusPunch < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon)
        super
        self.counter = 1
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :focus_punch
      end

      # Tell if the effect make the pokemon preparing an attack
      # @return [Boolean]
      def preparing_attack?
        return true
      end
    end
  end
end
