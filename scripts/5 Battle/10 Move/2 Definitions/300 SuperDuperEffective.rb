module Battle
  class Move
    # Move that is stronger if super effective
    class SuperDuperEffective < BasicWithSuccessfulEffect
      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @note The formula is the following:
      #       (((((((Level * 2 / 5) + 2) * BasePower * [Sp]Atk / 50) / [Sp]Def) * Mod1) + 2) *
      #         CH * Mod2 * R / 100) * STAB * Type1 * Type2 * Mod3)
      # @return [Integer]
      def damages(user, target)
        damage = super

        return (damage * (super_effective? ? 5461.0/4096 : 1)).to_i # ~1.33
      end
    end
    Move.register(:s_super_duper_effective, SuperDuperEffective)
  end
end
