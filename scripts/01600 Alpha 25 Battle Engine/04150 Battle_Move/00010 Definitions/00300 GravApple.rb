module Battle
  class Move
    class GravApple < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return power = power * 1.5 if @logic.terrain_effects.has?(:gravity)

        return power
      end
    end
    Move.register(:s_grav_apple, GravApple)
  end
end
