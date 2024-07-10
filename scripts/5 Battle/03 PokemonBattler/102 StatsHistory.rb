module PFM
  class PokemonBattler
    class StatHistory
      # Get the turn when it was used
      # @return [Integer]
      attr_reader :turn
      # :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @return [Symbol]
      attr_reader :stat
      # Get the power of the stat change
      # @return [Integer]
      attr_reader :power
      # Get the target of the stat change
      # @return [PFM::PokemonBattler]
      attr_reader :target
      # Get the launcher of the stat change
      # @return [PFM::PokemonBattler, nil]
      attr_reader :launcher
      # Get the move that cause the stat change
      # @return [Battle::Move, nil]
      attr_reader :move

      # Create a new Stat History
      # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @param power [Integer] power of the stat change
      # @param target [PFM::PokemonBattler] target of the stat change
      # @param launcher [PFM::PokemonBattler, nil] launcher of the stat change
      # @param move [Battle::Move, nil] move that cause the stat change
      def initialize(stat, power, target, launcher, move)
        @turn = $game_temp.battle_turn
        @stat = stat
        @power = power
        @target = target
        @launcher = launcher
        @move = move
      end

      # Tell if the move was used during last turn
      # @return [Boolean]
      def last_turn?
        return @turn == $game_temp.battle_turn - 1
      end

      # Tell if the move was used during the current turn
      # @return [Boolean]
      def current_turn?
        return @turn == $game_temp.battle_turn
      end

      # Get the db_symbol of the move
      # @return [Symbol]
      def db_symbol
        return move&.db_symbol
      end
    end
  end
end
