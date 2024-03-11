module Battle
  class Move
    # Solar Beam Move
    class SolarBeam < TwoTurnBase
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        power2 = power
        power2 *= 0.5 if $env.sandstorm? || $env.hail? || $env.rain?
        return power2
      end

      private

      # Check if the two turn move is executed in one turn
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean]
      def shortcut?(user, targets)
        return true if $env.sunny? || $env.hardsun?

        super
      end
    end

    Move.register(:s_solar_beam, SolarBeam)
  end
end
