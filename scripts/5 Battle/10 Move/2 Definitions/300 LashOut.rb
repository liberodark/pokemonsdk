module Battle
  class Move
    class LashOut < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return power unless user.stat_history&.last&.current_turn? && user.stat_history&.last&.power&.negative?

        log_data("power = #{power * 2} # after Move::LashOut")
        return power * 2
      end
    end

    Move.register(:s_lash_out, LashOut)
  end
end