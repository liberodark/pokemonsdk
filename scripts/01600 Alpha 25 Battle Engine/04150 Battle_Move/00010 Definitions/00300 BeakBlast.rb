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
        return unless can_pre_use_move?(user)

        @scene.display_message_and_wait(parse_text_with_pokemon(59, 1880, user))
        user.effects.add(Effects::BeakBlast.new(@logic, user))
        #TODO play charging animation
      end

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false unless @enabled

        return true
      end

      private 

      # Check if the user is able to display the message related to the move
      # @param user [PFM::PokemonBattler]
      def can_pre_use_move?(user)
        @enabled = false
        return false if (user.frozen? || user.asleep?)

        @enabled = true
        return true
      end
    end
    Move.register(:s_beak_blast, BeakBlast)
  end
end
