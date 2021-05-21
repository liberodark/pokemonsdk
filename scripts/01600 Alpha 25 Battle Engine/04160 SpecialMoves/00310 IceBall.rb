module Battle
  class Move
    # Ice Ball deals damage for 5 turns, doubling in power each turn. The move stops if it misses on any turn.
    # @see https://pokemondb.net/move/ice-ball
    # @see https://bulbapedia.bulbagarden.net/wiki/Ice_Ball_(move)
    # @see https://www.pokepedia.fr/Ball%27Glace
    class IceBall < Rollout
      # Return the chance of hit of the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Float]
      def chance_of_hit(user, target)
        # @type [Effects::Rollout]
        effect = user.effects.get(effect_name)
        return super unless effect
        # Acuracy lower 10% each use (90 -> 81 -> 73 -> 66 -> 57)
        result = (super * 0.9 ** effect.successive_uses).round
        log_data("chance of hit = #{result} # ice ball successive use : #{effect.successive_uses}")
        return result
      end
    end
    Move.register(:s_ice_ball, IceBall)
  end
end