module Battle
  class Move
    class DoubleIronBash < TwoHit
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return target.effects.has?(:minimize) ? power * 2 : power
      end

      # Check if the move bypass chance of hit and cannot fail
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def bypass_chance_of_hit?(user, target)
        return target.effects.has?(:minimize) ? true : super
      end
    end
    Move.register(:s_double_iron_bash, DoubleIronBash)
  end
end