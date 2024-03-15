module Battle
  class Move
    # Class managing the moves that get empowered by a specific field terrain
    class TerrainBoosting < Basic
      TERRAIN_MOVE = {
        psyblade: :electric_terrain
      }
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return @logic.field_terrain_effect.db_symbol == TERRAIN_MOVE[db_symbol] ? power * 1.5 : power
      end
    end

    Move.register(:s_terrain_boosting, TerrainBoosting)
  end
end
