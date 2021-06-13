module Battle
  class Move
    private

    # Mod1 multiplier calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod1(user, target)
      result = 1
      # Effects
      logic.each_effects(user, target) do |e|
        result *= e.mod1_multiplier(user, target, self)
      end
      # Mod1 = BRN × RL × TVT × SR × FF
      # TVT
      result *= calc_mod1_tvt(target)
      return result
    end

    # Calculate the TVT mod
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod1_tvt(target)
      return 1 if one_target? || $game_temp.vs_type == 1

      if self.target == :all_foe
        count = logic.allies_of(target).size + 1
      else
        count = logic.adjacent_allies_of(target).size + 1
      end
      return count > 1 ? 0.75 : 1
    end
  end
end
