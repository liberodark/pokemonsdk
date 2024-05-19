module Battle
  class Move
    # Accuracy depends of weather.
    # @see https://pokemondb.net/move/thunder
    # @see https://bulbapedia.bulbagarden.net/wiki/Bleakwind_Storm_(move)
    # @see https://bulbapedia.bulbagarden.net/wiki/Wildbolt_Storm_(move)
    # @see https://bulbapedia.bulbagarden.net/wiki/Sandsear_Storm_(move)
    # @see https://www.pokepedia.fr/Typhon_Hivernal
    # @see https://www.pokepedia.fr/Typhon_Fulgurant
    # @see https://www.pokepedia.fr/Typhon_Pyrosable
    # @note Springtide does NOT work the same.
    class GeniesStorm < Basic
      # Return the current accuracy of the move
      # @return [Integer]
      def accuracy
        al = @scene.logic.all_alive_battlers.any? { |battler| battler.has_ability?(:cloud_nine) || battler.has_ability?(:air_lock) }
        return super if al
        return 0 if $env.rain? || $env.hardrain?

        return super
      end
    end
    Move.register(:s_genies_storm, GeniesStorm)
  end
end
