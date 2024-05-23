module Battle
  module Effects
    # Implement the Torment effect
    class Torment < PokemonTiedEffectBase
      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if can_be_used?(user, move)

        move.show_usage_failure(user)
        return :prevent
      end

      # Function called when we try to check if the user cannot use a move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Proc, nil]
      def on_move_disabled_check(user, move)
        return if can_be_used?(user, move)

        return proc {
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 580, user))
        }
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :torment
      end

      private

      # Checks if the user can use the move
      # @param user [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Boolean]
      def can_be_used?(user, move)
        last_move = user.move_history.reject { |move| move.db_symbol == :struggle }.last

        return true if user != @pokemon
        return true if user.move_history.none?
        return true if move.db_symbol == :struggle
        return true if last_move.db_symbol != move.db_symbol
        return true if last_move.turn < user.last_sent_turn

        return false
      end
    end
  end
end
