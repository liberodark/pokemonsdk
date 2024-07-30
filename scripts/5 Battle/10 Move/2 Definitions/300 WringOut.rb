module Battle
  class Move
    # Class managing Crush Grip / Wring Out moves
    class WringOut < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        power = (max_power * target.hp_rate).clamp(1, Float::INFINITY)
        log_data("power = #{power} # after #{self.class} real_base_power")

        return power
      end

      # Get the max power the moves can have
      # @return [Integer]
      def max_power
        return 120
      end
    end

    # Class managing Hard Press move
    class HardPress < WringOut
      # Get the max power the moves can have
      # @return [Integer]
      def max_power
        return 100
      end
    end

    Move.register(:s_wring_out, WringOut)
    Move.register(:s_hard_press, HardPress)
  end
end
