module Battle
  class Move
    # Implement the Beak Blast move
    class BeakBlast < Basic
      # Is the move doing something before any other attack ?
      # @return [Boolean]
      def pre_attack?
        true
      end

      # Proceed the procedure before any other attack.
      # @param user [PFM::PokemonBattler]
      def proceed_pre_attack(user)
        @scene.display_message_and_wait(parse_text_with_pokemon(59, 1880, user))
        user.effects.add(Effects::BeakBlast.new(@logic, user))
        # @todo play charging animation
      end

    end
    Move.register(:s_beak_blast, BeakBlast)
  end
end
