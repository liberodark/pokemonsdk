module Battle
  class Move
    class WeatherBall < Basic
      # Return the current type of the move
      # @return [Integer]
      def type
        al = @scene.logic.all_alive_battlers.any? { |battler| battler.has_ability?(:cloud_nine) || battler.has_ability?(:air_lock) }
        return data_type(data.type).id if al
        return data_type(:fire).id if $env.sunny? || $env.hardsun?
        return data_type(:water).id if $env.rain? || $env.hardrain?
        return data_type(:ice).id if $env.hail?
        return data_type(:rock).id if $env.sandstorm?

        return data_type(data.type).id
      end

      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        base_power = $env.normal? ? 50 : 100
        return base_power
      end
    end
    Move.register(:s_weather_ball, WeatherBall)
  end
end
