module Battle
  class Move
    class Psyshock < Basic
      def physical?
        return true
      end
    end
    Move.register(:s_psyshock, Psyshock)
  end
end
