module PFM
  class Pokemon
    # Tell if the Creature likes flavor
    # @param flavor [Symbol]
    def flavor_liked?(flavor)
      return false if no_preferences?

      return Configs.flavors.nature_liking_flavor[flavor].include?(nature_id)
    end

    # Tell if the Creature dislikes flavor
    # @param flavor [Symbol]
    def flavor_disliked?(flavor)
      return false if no_preferences?

      return Configs.flavors.nature_disliking_flavor[flavor].include?(nature_id)
    end

    # Check if the Creature has a nature with no preferences
    def no_preferences?
      return Configs.flavors.nature_with_no_preferences.include?(nature_id)
    end
  end
end
