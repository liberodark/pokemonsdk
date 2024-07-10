module Battle
  class Move
    class WringOut < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return (max_power * target.hp_rate).clamp(1, Float::INFINITY)
      end

      # Get the max power the moves can have
      # @return [Integer]
      def max_power
        return 120
      end
    end
    Move.register(:s_wring_out, WringOut)
  end
end
