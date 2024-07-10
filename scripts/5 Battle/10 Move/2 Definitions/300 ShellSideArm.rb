module Battle
  class Move
    class ShellSideArm < Basic
      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @note The formula is the following:
      #       (((((((Level * 2 / 5) + 2) * BasePower * [Sp]Atk / 50) / [Sp]Def) * Mod1) + 2) *
      #         CH * Mod2 * R / 100) * STAB * Type1 * Type2 * Mod3)
      # @return [Integer]
      def damages(user, target)
        @physical = true
        @special = false
        physical_hp = super

        @physical = false
        @special = true
        special_hp = super

        if physical_hp > special_hp
          @physical = true
          @special = false
          return physical_hp
        else
          return special_hp
        end
      end

      # Is the skill physical ?
      # @return [Boolean]
      def physical?
        return @physical.nil? ? super : @physical
      end

      # Is the skill special ?
      # @return [Boolean]
      def special?
        return @special.nil? ? super : @special
      end

      # Is the skill direct ?
      # @return [Boolean]
      def direct?
        return @physical
      end
    end
    Move.register(:s_shell_side_arm, ShellSideArm)
  end
end
