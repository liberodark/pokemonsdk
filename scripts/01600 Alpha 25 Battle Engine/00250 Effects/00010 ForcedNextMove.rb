module Battle
  module Effects
    # Give functions to manage a move that force the next one. Must be used in a EffectBase child class.
    module ForceNextMove
      # Get the move the Pokemon has to use
      # @return [Battle::Move]
      attr_reader :move
      # Get the targets of the move
      # @return [Array<PFM::PokemonBattler>]
      attr_reader :targets
      
      # Tell if the effect forces the next move
      # @return [Boolean]
      def force_next_move?
        return true
      end

      private
      
      # Create a new Forced next move effect
      # @param move [Battle::Move]
      # @param counter [Integer] number of turn the move is forced to be used
      # @param targets [Array<PFM::PokemonBattler>]
      def init_force_next_move(move, targets, counter = 2)
        @move = move
        @targets = targets
        self.counter = counter
      end
    end

    # Move that force the next move
    class ForceNextMoveBase < PokemonTiedEffectBase
      include ForceNextMove

      # Create a new Forced next move effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param counter [Integer] number of turn the move is forced to be used
      # @param targets [Array<PFM::PokemonBattler>]
      # @param turncount [Integer] (default: 5) number of turn the effect proc (including the current one)
      def initialize(logic, target, move, targets, turncount = 2)
        super(logic, target)
        init_force_next_move(move, targets, turncount)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        :force_next_move_base
      end
    end
  end
end
