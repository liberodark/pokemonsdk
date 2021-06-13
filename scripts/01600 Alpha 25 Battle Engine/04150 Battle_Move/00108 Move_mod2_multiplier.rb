module Battle
  class Move
    private

    # Mod2 multiplier calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod2(user, target)
      update_use_count(user)
      result = 1
      # Effects
      logic.each_effects(user, target) do |e|
        result *= e.mod2_multiplier(user, target, self)
      end
      result *= 1.5 if db_symbol == :me_first
      return result
    end

    # Update the move use count
    # @param user [PFM::PokemonBattler] user of the move
    def update_use_count(user)
      if user.last_successfull_move_is?(db_symbol)
        @consecutive_use_count += 1
      else
        @consecutive_use_count = 0
      end
    end
  end
end
