module PFM
  class Pokemon
    # Tell if the Creature likes flavor
    # @param flavor [Symbol]
    def flavor_liked?(flavor)
      return false if no_preferences?

      return data_nature(nature_db_symbol).liked_flavor == flavor
    end

    # Tell if the Creature dislikes flavor
    # @param flavor [Symbol]
    def flavor_disliked?(flavor)
      return false if no_preferences?

      return data_nature(nature_db_symbol).disliked_flavor == flavor
    end

    # Check if the Creature has a nature with no preferences
    def no_preferences?
      nature = data_nature(nature_db_symbol)
      return true if nature.liked_flavor == :none && nature.disliked_flavor == :none

      return false
    end
  end
end
