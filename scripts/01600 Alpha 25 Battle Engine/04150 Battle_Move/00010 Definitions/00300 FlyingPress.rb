module Battle
  class Move
    # Move that has a flying type as second type
    class FlyingPress < Move
      # Get the types of the move with 1st type being affected by effects
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Array<Integer>] list of types of the move
      def definitive_types(user, target)
        super << data_type(:flying).id
      end
    end

    Move.register(:s_flying_press, FlyingPress)
  end
end
