module Battle
  class Move
    class FishiousRend < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        n = 1
        n *= damage_multiplier if logic.battler_attacks_before?(user, target) || target.switching?

        return super * n
      end

      private

      # Damage multiplier if the effect procs
      # @return [Integer, Float]
      def damage_multiplier
        return 2
      end
    end
    register(:s_fishious_rend, FishiousRend)
  end
end
