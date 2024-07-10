module Battle
  class Move
    # Move that has a flying type as second type
    class FlyingPress < Basic
      # Get the types of the move with 1st type being affected by effects
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Array<Integer>] list of types of the move
      def definitive_types(user, target)
        super << data_type(second_type).id
      end

      # Method calculating the damages done by the actual move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def damages(user, target)
        return target.effects.has?(:minimize) ? super * 2 : super
      end

      # Check if the move bypass chance of hit and cannot fail
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def bypass_chance_of_hit?(user, target)
        return true if target.effects.has?(:minimize)

        super
      end

      private

      # Get the second type of the move
      # @return [Symbol]
      def second_type
        return :flying
      end
    end

    Move.register(:s_flying_press, FlyingPress)
  end
end
