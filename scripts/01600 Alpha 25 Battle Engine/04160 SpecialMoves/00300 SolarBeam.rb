module Battle
  class Move
    # The user of Solar Beam will absorb light on the first turn. On the second turn, Solar Beam deals damage.
    # @see https://pokemondb.net/move/solar-beam
    # @see https://bulbapedia.bulbagarden.net/wiki/Solar_Beam_(move)
    # @see https://www.pokepedia.fr/Lance-Soleil
    class SolarBeam < Basic
      include Mechanics::TwoTurn

      # Return the actual base power of the move
      # @return [Integer]
      def power
        return super / 2 if $env.sandstorm? || $env.hail? || $env.rain?

        return super
      end

      private

      # Check if the user can skip the first move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean] true if the move is actually one move
      def check_shortcut_turn_1(user, targets)
        return true if $env.sunny?

        return two_turn_check_shortcut_turn_1(user, targets)
      end

      # Display the message and the animation of the turn
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      def proceed_message_turn_1(user, targets)
        @scene.display_message_and_wait(parse_text_with_pokemon(19, 553, user))
      end
    end
    Move.register(:s_solar_beam, SolarBeam)
  end
end
