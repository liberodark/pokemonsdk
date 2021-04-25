module Battle
    class Move
      # Class managing Origin Pulse move
      class OriginPulse < Basic
        # Get the real base power of the move (taking in account all parameter)
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @return [Integer]
        def real_base_power(user, target)
          if user.has_ability?(:mega_launcher)
            n = (power * 0.5) + power
            log_data("Power of Mega Launcher (Boosted): #{n}")
            return n
          end
          log_data("Power of Mega Launcher (Unboosted): #{power}")
          return power
        end
      end
      Move.register(:s_origin_pulse, OriginPulse)
    end
  end