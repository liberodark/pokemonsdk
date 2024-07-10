module Battle
  class Move
    # Class that manage Rage Fist move
    class RageFist < Basic
      # Base power calculation
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        power = super

        damage_taken = user.damage_history.count(&:move)
        new_power = (power + damage_taken * 50).clamp(1, 350)
        log_data("power = #{new_power} # after Move::RageFist calc")

        return new_power
      end
    end
    Move.register(:s_rage_fist, RageFist)
  end
end
