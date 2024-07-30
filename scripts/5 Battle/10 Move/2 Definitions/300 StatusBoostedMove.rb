module Battle
  class Move
    # Class managing Facade / InfernalParade / Bitter Malice moves
    class StatusBoostedMove < Basic
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return power unless boosted?(user, target)

        new_power = power * factor
        log_data("power = #{new_power} # after #{self.class} real_base_power")

        return new_power
      end

      # Check if the move must be boosted
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def boosted?(user, target)
        raise 'This method should be implemented in the subclass'
      end

      # Returns the multiplier applied to the move's base power
      # @return [Integer]
      def factor
        return 2
      end
    end

    # Class managing Infernal Parade / Bitter Malice move
    class InfernalParade < StatusBoostedMove
      # Check if the move must be boosted
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def boosted?(user, target)
        return target.status?
      end
    end

    # Class managing Facade move
    class Facade < StatusBoostedMove
      # Check if the move must be boosted
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def boosted?(user, target)
        return user.burn? || user.paralyzed? || user.poisoned? || user.toxic?
      end
    end

    Move.register(:s_infernal_parade, InfernalParade)
    Move.register(:s_bitter_malice, InfernalParade)
    Move.register(:s_facade, Facade)
  end
end
