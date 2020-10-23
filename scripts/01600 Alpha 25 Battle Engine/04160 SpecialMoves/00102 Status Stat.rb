module Battle
  class Move
    # Class describing a self stat move (damage + potential status + potential stat to user)
    class StatusStat < Move
      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        raise 'Stat and Status move should not get power' if power > 0
        raise 'Stat and Status move ignore effect chance!' if effect_chance.to_i > 0

        return true
      end
    end

    Move.register(:s_stat, StatusStat)
    Move.register(:s_status, StatusStat)
  end
end
