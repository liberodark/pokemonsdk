module Battle
  class Move
    class CustomStatsBased < Basic
      # Physical moves that use the special attack
      ATS_PHYSICAL_MOVES = %i[psyshock secret_sword]
      # Special moves that use the attack
      ATK_SPECIAL_MOVES = %i[]

      # Is the skill physical ?
      # @return [Boolean]
      def physical?
        return ATS_PHYSICAL_MOVES.include?(db_symbol)
      end

      # Is the skill special ?
      # @return [Boolean]
      def special?
        return ATK_SPECIAL_MOVES.include?(db_symbol)
      end

      # Get the basis atk for the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param ph_move [Boolean] true: physical, false: special
      # @return [Integer]
      def calc_sp_atk_basis(user, target, ph_move)
        return ph_move ? user.ats_basis : user.atk_basis
      end

      # Statistic modifier calculation: ATK/ATS
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param ph_move [Boolean] true: physical, false: special
      # @return [Integer]
      def calc_atk_stat_modifier(user, target, ph_move)
        modifier = ph_move ? user.ats_modifier : user.atk_modifier
        modifier = modifier > 1 ? modifier : 1 if critical_hit?
        return modifier
      end
    end
    Move.register(:s_custom_stats_based, CustomStatsBased)
    Move.register(:s_psyshock, CustomStatsBased)
  end
end
