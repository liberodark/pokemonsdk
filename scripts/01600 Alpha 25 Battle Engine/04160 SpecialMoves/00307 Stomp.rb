module Battle
  class Move
    class Stomp < Basic
      # Method calculating the damages done by the actual move if the target has minimize effect
      # @return [Integer]
      def damages(user, target)
        return super * 2 if target.effects.has?(:minimize)
      end

      # Return the chance of hit of the move
      # @return [Float]
      def chance_of_hit(user, target)
        return 100 if target.effects.has?(:minimize)

        super
      end
    end

    Move.register(:s_stomp, Stomp)
  end
end
