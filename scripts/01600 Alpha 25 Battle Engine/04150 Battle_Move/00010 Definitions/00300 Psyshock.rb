module Battle
  class Move
    class Psyshock < Basic
      # Calc the dfe of the target instead of dfs (also applies for Secret Sword)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def calc_sp_def(user, target)
        # [Sp]Def = Stat * SM * Mod * SX
        ph_move = true
        # Stat
        result = calc_sp_def_basis(user, target, ph_move)
        # SM (Only if non-critical hit)
        result = (result * calc_def_stat_modifier(user, target, ph_move)).floor
        # Effects
        logic.each_effects(user, target) do |e|
          result = (result * e.sp_def_multiplier(user, target, self)).floor
        end
        return result
      end
    end
    Move.register(:s_psyshock, Psyshock)
  end
end
