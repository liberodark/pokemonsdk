module Battle
  class Move
    # Class that manage Assurance move
    # @see https://bulbapedia.bulbagarden.net/wiki/Assurance_(move)
    # @see https://pokemondb.net/move/Assurance
    # @see https://www.pokepedia.fr/Assurance
    class Assurance < Basic
      # Base power calculation
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def calc_base_power(user, target)
        result = super
        damage_took = target.damage_history.any?(&:current_turn?)
        log_data("power = #{result * (damage_took ? 2 : 1)} # after Move::Assurance calc")
        return result * (damage_took ? 2 : 1)
      end
    end
    Move.register(:s_assurance, Assurance)
  end
end
