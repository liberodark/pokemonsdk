module Battle
  class Move
    class StompingTantrum < Basic
      # Base power calculation
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return power unless boosted?(user, target)

        log_data("Stomping Tantrum : real_base_power = #{power * 2}")
        return power * 2
      end

      private

      # Determines if the power of Stomping Tantrum should be boosted
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def boosted?(user, target)
        user_last_move = user.move_history&.last
        user_last_successful_move = user.successful_move_history&.last

        return false if user_last_move.nil?
        return false if user_last_successful_move&.turn == user_last_move.turn

        return true
      end
    end

    register(:s_stomping_tantrum, StompingTantrum)
  end
end
