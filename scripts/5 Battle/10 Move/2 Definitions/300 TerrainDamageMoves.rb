module Battle
  class Move
    # Move that execute Misty Explosion
    class MistyExplosion < SelfDestruct
      def real_base_power(user, target)
        return power * 1.5 if @logic.field_terrain_effect.misty?

        return super
      end
    end
    register(:s_misty_explosion, MistyExplosion)

    # Move that execute Expanding Force
    class ExpandingForce < BasicWithSuccessfulEffect
      def real_base_power(user, target)
        return power * 1.5 if @logic.field_terrain_effect.psychic? && user.grounded?

        return super
      end

      def deal_effect(user, actual_targets)
        return unless user.grounded? && @logic.field_terrain_effect.psychic?

        targets = @logic.adjacent_allies_of(actual_targets.first)
        deal_damage(user, targets)
      end
    end
    register(:s_expanding_force, ExpandingForce)

    # Move that execute Rising Voltage
    class RisingVoltage < Basic
      def real_base_power(user, target)
        return power * 2 if @logic.field_terrain_effect.electric? && target.grounded?

        return super
      end
    end
    register(:s_rising_voltage, RisingVoltage)

    # Move that execute Grassy Glide
    class GrassyGlide < BasicWithSuccessfulEffect
      # Return the priority of the skill
      # @param user [PFM::PokemonBattler] user for the priority check
      # @return [Integer]
      def priority(user = nil)
        priority = super
        priority += 1 if priority < 14 && @logic.field_terrain_effect.grassy? && user && user.grounded?

        return priority
      end
    end
    register(:s_grassy_glide, GrassyGlide)
  end
end
