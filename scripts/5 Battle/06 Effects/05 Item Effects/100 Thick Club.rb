module Battle
  module Effects
    class Item
      class ThickClub < Item
        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 2 if %i[cubone marowak].include?(@target.db_symbol)

          return super
        end
      end

      register(:thick_club, ThickClub)
    end
  end
end
