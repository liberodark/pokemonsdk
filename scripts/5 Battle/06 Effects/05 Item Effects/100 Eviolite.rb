module Battle
  module Effects
    class Item
      class Eviolite < Item
        # Give the dfe modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfe_modifier
          return 1.5 if @target.data.evolutions.reject { |evolution| evolution.conditions.any? { |condition| condition[:type] == :gemme } }.any?

          return super
        end
        alias dfs_modifier dfe_modifier
      end

      register(:eviolite, Eviolite)
    end
  end
end
