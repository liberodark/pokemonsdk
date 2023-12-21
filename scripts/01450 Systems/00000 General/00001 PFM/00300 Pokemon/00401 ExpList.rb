module PFM
  class Pokemon
    # Helper class helping to get exp values based on each kind of equation
    class ExpList
      include Enumerable
      # List of method name per kind of exp
      KIND_TO_METHOD = %i[exp_fast exp_normal exp_slow exp_parabolic exp_eratic exp_fluctuating]
      # Create a new ExpList
      # @param kind [Integer] kind of exp
      def initialize(kind)
        @method = KIND_TO_METHOD[kind] || :exp_normal
      end

      # Get the total amount of exp to level up to the level parameter
      # @param level [Integer]
      # @return [Integer]
      def [](level)
        send(@method, level)
      end

      # Iterate over all the experience curve
      # @yieldparam total_exp [Integer] the total exp at the current level
      def each
        return to_enum(__method__) unless block_given?

        1.upto(size) { |i| yield(self[i]) }
      end

      # Get the size of the exp list table for this curve
      def size
        Configs.settings.max_level
      end

      private

      def exp_fast(level)
        return Integer(4 * (level**3) / 5)
      end

      def exp_normal(level)
        return Integer(level**3)
      end

      def exp_slow(level)
        return Integer(5 * (level**3) / 4)
      end

      def exp_parabolic(level)
        return 1 if level <= 1

        return Integer((6 * (level**3) / 5 - 15 * (level**2) + 100 * level - 140))
      end

      def exp_eratic(level)
        return Integer(level**3 * (100 - level) / 50) if level <= 50
        return Integer(level**3 * (150 - level) / 100) if level <= 68
        return Integer(level**3 * ((1911 - 10 * level) / 3) / 500) if level <= 98
        return Integer(level**3 * (160 - level) / 100) if level <= 100

        return Integer(600_000 + 103_364 * (level - 100) + Math.cos(level) * 30_000)
      end

      def exp_fluctuating(level)
        return Integer(level**3 * (24 + (level + 1) / 3) / 50) if level <= 15
        return Integer(level**3 * (14 + level) / 50) if level <= 35

        return Integer(level**3 * (32 + (level / 2)) / 50)
      end
    end
  end
end
