module Battle
  class Move
    # Fickle Beam has 20% chance of doubling its base power.
    class FickleBeam < Basic
      # Function which permit things to happen before the move's animation
      def post_accuracy_check_move(user, actual_targets)
        @empowered = false
        if bchance?(0.3, logic)
          @empowered = true
          scene.display_message_and_wait(parse_text_with_pokemon(19, 547, user))
        end
      end

      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def real_base_power(user, target)
        return power * (@empowered ? 2 : 1)
      end
    end
    Move.register(:s_fickle_beam, FickleBeam)
  end
end
