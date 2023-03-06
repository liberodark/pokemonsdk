module Battle
  module Effects
    # Class managing Burn Up Effect
    class BurnUp < PokemonTiedEffectBase
      include Mechanics::NeutralizeType

      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param turn_count [Integer]
      def initialize(logic, pokemon, turn_count)
        super(logic, pokemon)
        neutralize_type_initialize(pokemon, turn_count)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :burn_up
      end

      private

      # Get the neutralized types
      # @return [Array<Integer>]
      def neutralyzed_types
        return [data_type(:fire).id]
      end
    end
  end
end
