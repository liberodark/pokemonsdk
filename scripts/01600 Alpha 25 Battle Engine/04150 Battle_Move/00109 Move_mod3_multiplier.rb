module Battle
  class Move
    private

    # Mod3 calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod3(user, target)
      # Mod3 = SRF * EB * TL * TRB
      result = 1
      # Effects
      logic.each_effects(user, target) do |e|
        result *= e.mod3_multiplier(user, target, self)
      end
      return result
    end
  end
end
