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
      # @param counter [Integer] number of turn the move is forced to be used
      # @param targets [Array<PFM::PokemonBattler>]
      def initialize(logic, target, move, targets, counter = 1)
        super(logic, target)
        @move = move
        @targets = targets
        self.counter = counter + 1
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :forced_next_move
      end

      # Forced Next Move for rollout so it stores additional information
      class Rollout < ForcedNextMove
        # Get the number of successiv use of the move
        # @return [Integer]
        attr_accessor :successive_uses

        # Create a new Forced next move effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @param counter [Integer] number of turn the move is forced to be used
        # @param targets [Array<PFM::PokemonBattler>]
        def initialize(logic, target, move, targets)
          super(logic, target, move, targets, 4)
          @successive_uses = 1
        end
      end

      # Forced Next Move that can be disturbed
      class Disturbable < ForcedNextMove
        # Get the distirbed flag
        # @return [Boolean]
        attr_accessor :disturbed

        # Create a new Forced next move effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @param counter [Integer] number of turn the move is forced to be used
        # @param targets [Array<PFM::PokemonBattler>]
        def initialize(logic, target, move, targets, counter = 2)
          super
          @disturbed = false
        end
      end
    end
  end
end
