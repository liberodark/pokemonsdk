module Battle
  module Effects
    # Implement the Forced next move effect
    class ForcedNextMove < PokemonTiedEffectBase
      # Get the move the Pokemon has to use
      # @return [Battle::Move]
      attr_reader :move
      # Get the targets of the move
      # @return [Array<PFM::PokemonBattler>]
      attr_reader :targets
      # Create a new Forced next move effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param targets [Array<PFM::PokemonBattler>]
      def initialize(logic, target, move, targets)
        super(logic, target)
        @move = move
        @targets = targets
        self.counter = 2
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :forced_next_move
      end
    end
  end
end
