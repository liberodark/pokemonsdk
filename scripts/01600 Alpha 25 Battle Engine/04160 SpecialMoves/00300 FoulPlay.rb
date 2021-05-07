module Battle
  class Move
    # Class managing Foul Play move
    class FoulPlay < Basic
      # [Spe]atk calculation
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def calc_sp_atk(user, target)
        # [Sp]Atk = Stat * SM * AM * IM
        ph_move = physical?
        # Stat
        result = ph_move ? target.atk_basis : target.ats_basis
        # SM (Only if non-critical hit)
        result = (result * calc_atk_stat_modifier(user, target, ph_move)).floor
        # Flower Gift
        result = (result * flower_gift_atk_calc(user, ph_move)).floor
        # AM
        am = send((ph_move ? ATK_ABILITY_MODIFIER : ATS_ABILITY_MODIFIER)[user.battle_ability_db_symbol], user, target)
        result = (result * am).floor
        # IM
        return (result * send((ph_move ? ATK_ITEM_MODIFIER : ATS_ITEM_MODIFIER)[user.battle_item_db_symbol], user, target)).floor
      end

      # Statistic modifier calculation: ATK/ATS
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param ph_move [Boolean] true: physical, false: special
      # @return [Integer]
      def calc_atk_stat_modifier(user, target, ph_move)
        return 1 if critical_hit?
        return 1 if target.has_ability?(:unaware) && !UNAWARE_IGNORING_ABILITIES.include?(user.battle_ability_db_symbol)

        return ph_move ? target.atk_modifier : target.ats_modifier
      end
    end
    Move.register(:s_foul_play, FoulPlay)
  end
end
