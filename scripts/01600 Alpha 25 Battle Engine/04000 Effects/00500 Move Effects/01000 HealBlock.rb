module Battle
  module Effects
    # Implement the Miracle Eye effect
    class HealBlock < PokemonTiedEffectBase
      # Create a new Pokemon HealBlock effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param turn_count [Integer]
      def initialize(logic, target, turn_count = 5)
        super(logic, target)
        self.counter = turn_count
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :heal_block
      end
    end
  end
end
