module Battle
  class Move
    class RevelationDance < Basic
      def definitive_types(user, target)
        return [user.type1] if user.type1 && user.type1 != 0
        
        first_type, *rest = super
        return [first_type, *rest]
      end
    end
    Move.register(:s_revelation_dance, RevelationDance)
  end
end
