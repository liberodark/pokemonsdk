module Battle
  module Effects
    # Class managing Triple Arrows move effect
    class TripleArrows < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param counter [Integer]
      def initialize(logic, pokemon, counter)
        super(logic, pokemon)
        self.counter = counter
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :triple_arrows
      end

      # Transfer the effect to the given pokemon via baton switch
      # @param with [PFM::Battler] the pokemon switched in
      # @return [Battle::Effects::PokemonTiedEffectBase, nil] nil if the effect is not transferable, otherwise the effect
      def baton_switch_transfer(with)
        return self.class.new(@logic, with)
      end
    end
  end
end
