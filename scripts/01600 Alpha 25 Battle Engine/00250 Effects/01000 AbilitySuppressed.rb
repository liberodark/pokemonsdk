module Battle
  module Effects
    # Implement the ability suppression (Gastro Acid)
    class AbilitySuppressed < PokemonTiedEffectBase
      # Create a new AbilitySuppressed effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      def initialize(logic, target)
        super(logic, target)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :ability_suppressed
      end
    end
  end
end