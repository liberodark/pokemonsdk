module Battle
  class Move
    class LastRespects < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        ko_count = @logic.retrieve_party_from_battler(user).sum(&:ko_count)
        multiplier = (ko_count + 1).clamp(1, max)
        log_data("power = #{power * multiplier} # after Move::LastRespects real_base_power")

        return power * multiplier
      end

      private

      # Returns the maximum value for the multiplier clamp.
      # @return [Integer]
      def max
        return 101
      end
    end

    Move.register(:s_last_respects, LastRespects)
  end
end
