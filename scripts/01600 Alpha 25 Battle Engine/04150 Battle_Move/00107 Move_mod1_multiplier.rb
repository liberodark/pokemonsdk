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
      # SR
      result *= calc_mod1_sr
      # FT
      result *= calc_mod1_ft(user, target)
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

    # Calculate the SR mod
    # @return [Numeric]
    def calc_mod1_sr
      if $env.sunny?
        return 1.5 if type == GameData::Types::FIRE
        return 0.5 if type == GameData::Types::WATER
      elsif $env.rain?
        return 0.5 if type == GameData::Types::FIRE
        return 1.5 if type == GameData::Types::WATER
      end
      return 1
    end

    GRASSY_REDUCED_MOVES = %i[earthquake magnitude bulldoze]
    # Calculate the FT mod
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod1_ft(user, target)
      if $env.terrain_psychic?
        return 1.5 if type == GameData::Types::PSYCHIC && user.affected_by_terrain?
      elsif $env.terrain_grassy?
        return 1.5 if type == GameData::Types::GRASS && user.affected_by_terrain?
        return 0.5 if GRASSY_REDUCED_MOVES.include?(db_symbol) && user.affected_by_terrain?
      elsif $env.terrain_electric?
        return 1.5 if type == GameData::Types::ELECTRIC && user.affected_by_terrain?
      elsif $env.terrain_misty?
        return 0.5 if type == GameData::Types::DRAGON && target.affected_by_terrain? # Not a mistake, it's actually the target
      end
      return 1
    end
  end
end
