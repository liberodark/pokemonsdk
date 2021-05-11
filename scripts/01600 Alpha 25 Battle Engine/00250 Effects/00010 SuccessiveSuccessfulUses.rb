module Battle
  module Effects
    # Effect that store successfull move use count
    class SuccessiveSuccessfulUses < PokemonTiedEffectBase
      # Create a new Fury Cutter effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon, move)
        super(logic, pokemon)
        @successive_uses = 0
        @move_db_symbol = move.db_symbol
      end

      # Return the number of successive succesful use of the move.
      # @return [Integer]
      def successive_uses
        return @successive_uses if @pokemon.move_history.last&.last_turn? && @pokemon.last_successfull_move_is?(@move_db_symbol)
        return @successive_uses if @pokemon.move_history.last&.last_turn? && accepted_moves.any? {|move_sym| @pokemon.last_successfull_move_is?(move_sym)}
        return @successive_uses = 0
      end

      # Increase the successive uses by one
      def increase
        @successive_uses += 1
      end

      # Return the symbol of the effect.
      # @return [Symbol]
      def name
        :successive_successful_uses
      end
      
      private 

      # List of the moves that don't break the continuity and don't increment
      # @type [Array[Symbol]]
      ACCEPTED_MOVES = %i[mirror_move]

      # List of the moves that don't break the continuity and don't increment
      # @return [Array[Symbol]]
      def accepted_moves
        ACCEPTED_MOVES
      end
    end

    # Effect that manage Fury Cutter effect
    class FuryCutter < SuccessiveSuccessfulUses
      # Return the symbol of the effect.
      # @return [Symbol]
      def name
        :fury_cutter
      end
    end
  end
end