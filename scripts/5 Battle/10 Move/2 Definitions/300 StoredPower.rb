module Battle
  class Move
    # Move that deals more damage if user has any stat boost
    class StoredPower < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        base_power = db_symbol == :punishment ? 60 : power
        stat_count = stat_increase_count(db_symbol == :punishment ? target : user)
        stat_count = stat_count.clamp(0, 7) if db_symbol == :punishment
        return 20 * stat_count + base_power
      end

      private

      # Get the number of increased stats
      # @param pokemon [PFM::PokemonBattler] Pokémon whose stats stages are checked
      # @return [Integer]
      def stat_increase_count(pokemon)
        return pokemon.battle_stage.select(&:positive?).sum
      end
    end

    Move.register(:s_stored_power, StoredPower)
  end
end
