module Studio
  class Nature
    # ID of the nature
    # @return [Integer]
    attr_reader :id

    # db_symbol of the nature
    # @return [Symbol]
    attr_reader :db_symbol

    # Hash containing the stats
    # @return [Hash{Symbol=>Integer}]
    attr_reader :stats

    # Hash containing the liked and disliked flavors
    # @return [Hash{Symbol=>Symbol}]
    attr_reader :flavors

    # Get the nature name
    # @return [String]
    def name
      return text_get(8, @id)
    end

    # Get the atk modifier of the nature
    # @return [Integer]
    def atk
      return stats[:atk]
    end

    # Get the dfe modifier of the nature
    # @return [Integer]
    def dfe
      return stats[:dfe]
    end

    # Get the ats modifier of the nature
    # @return [Integer]
    def ats
      return stats[:ats]
    end

    # Get the dfs modifier of the nature
    # @return [Integer]
    def dfs
      return stats[:dfs]
    end

    # Get the spd modifier of the nature
    # @return [Integer]
    def spd
      return stats[:spd]
    end

    # Get the important data in an array form
    # Used in multiple contexts so it's easier to just return the same thing as before
    # @return [Array<Integer>] [text_id, atk%, dfe%, spd%, ats%, dfs%]
    def to_a
      return [id, atk, dfe, spd, ats, dfs]
    end

    # Get the liked flavor of the nature
    # @return [Symbol]
    def liked_flavor
      return flavors[:liked]
    end

    # Get the disliked flavor of the nature
    # @return [Symbol]
    def disliked_flavor
      return flavors[:disliked]
    end
  end
end
