module Battle
  class Move
    private

    # Mod1 multiplier calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod1(user, target)
      # Mod1 = BRN × RL × TVT × SR × FF
      # BRN
      result = calc_mod1_brn(user)
      # RL
      result *= calc_mod1_rl(user, target)
      # TVT
      result *= calc_mod1_tvt(target)
      # SR
      result *= calc_mod1_sr
      # FT
      result *= calc_mod1_ft
      # FF
      return result * calc_mod1_ff(user, target)
    end

    # Calculate the burn mod
    # @param user [PFM::PokemonBattler] user of the move
    # @return [Numeric]
    def calc_mod1_brn(user)
      return 1 unless physical? && user.burn?
      return 1 if user.has_ability?(:guts)

      return VAL_0_5
    end

    # Calculate the RL mod
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod1_rl(user, target)
      return 1 if critical_hit?
      return 1 if user.has_ability?(:infiltrator)

      if physical?
        return 1 unless logic.bank_effects[target.bank].has?(:reflect)
      else
        return 1 unless logic.bank_effects[target.bank].has?(:light_screen)
      end
      return $game_temp.vs_type == 2 ? (2 / 3.0) : VAL_0_5
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

    # Calculate the SR mod
    # @return [Numeric]
    def calc_mod1_sr
      if $env.sunny?
        return 1.5 if type == GameData::Types::FIRE
        return VAL_0_5 if type == GameData::Types::WATER
      elsif $env.rain?
        return VAL_0_5 if type == GameData::Types::FIRE
        return 1.5 if type == GameData::Types::WATER
      end
      return 1
    end

    GRASSY_REDUCED_MOVES = %i[earthquake magnitude bulldoze]
    # Calculate the FT mod
    # @return [Numeric]
    def calc_mod1_ft
      if $env.terrain_psychic?
        return 1.33 if type == GameData::Types::PSYCHIC
      elsif $env.terrain_grassy?
        return 1.33 if type == GameData::Types::GRASS
      elsif $env.terrain_electric?
        return 1.33 if type == GameData::Types::ELECTRIC
      elsif $env.terrain_misty?
        return VAL_0_5 if type == GameData::Types::DRAGON
      elsif $env.terrain_grassy?
        return VAL_0_5 if GRASSY_REDUCED_MOVES.include?(db_symbol)
      end
      return 1
    end


    # Calculate the Flash Fire mod
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod1_ff(user, target)
      if target.can_be_lowered_or_canceled?(user.has_ability?(:flash_fire))
        return 1.5 if user.last_hit_by_move&.type == GameData::Types::FIRE
      end
      return 1
    end
  end
end
