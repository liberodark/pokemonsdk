module Battle
  class Move
    # Class managing Magnitude move
    # @note : https://bulbapedia.bulbagarden.net/wiki/Magnitude_(move), https://pokemondb.net/move/magnitude 
    # Effect version : Generations VI
    # Tests:
    # * Double damages if target is at the second turn of Dig : Done
    # * Half damages if Grassy Terrain : Done
    # * Texts : Done
    class Magnitude < Basic
      private

      # Show the move usage message
      # @param user [PFM::PokemonBattler] user of the move
      def usage_message(user)
        super(user)
        # Pick a random magnitude data
        dice = logic.generic_rng.rand(100).floor
        magnitude_data = MAGNITUDE_TABLE.find { |row| row[0] > dice } || MAGNITUDE_TABLE[0]
        @magnitude_power = magnitude_data[1]
        log_data("magnitude power #{@magnitude_power} # #{magnitude_data}")
        @scene.display_message_and_wait(parse_text(18, magnitude_data[2]))
      end

      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, targets)
        return @magnitude_power
      end

      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def damages(user, target)
        if (e = target.effects.get(:out_of_reach)) && !e&.on_move_prevention_target(user, target, self)
          d = super(user, target)
          log_data("damage = #{d * 2} # #{d} * 2 (magnitude overhall damages double when target is using dig)")
          return (d * 2).floor
        end
        return super(user, target)
      end

      # Damage table
      # [probability_of_100, power, text]
      # Sum of probabilities must be 100
      MAGNITUDE_TABLE = [
        [5, 10, 108],
        [15, 30, 109],
        [35, 50, 110],
        [65, 70, 111],
        [85, 90, 112],
        [95, 110, 113],
        [100, 150, 114]
      ]
    end
    Move.register(:s_magnitude, Magnitude)
  end
end