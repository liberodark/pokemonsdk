module Battle
  class Move
    class TerrainPulse < Basic
      # Return the current type of the move
      # @return [Integer]
      def type
        return data_type(:electric).id if @logic.field_terrain_effect.electric?
        return data_type(:grass).id if @logic.field_terrain_effect.grassy?
        return data_type(:psychic).id if @logic.field_terrain_effect.psychic?
        return data_type(:fairy).id if @logic.field_terrain_effect.misty?

        return data_type(data.type).id
      end

      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        base_power = user.grounded? && !@logic.field_terrain_effect.none? ? 100 : 50
        return base_power
      end
    end
    Move.register(:s_terrain_pulse, TerrainPulse)
  end
end
