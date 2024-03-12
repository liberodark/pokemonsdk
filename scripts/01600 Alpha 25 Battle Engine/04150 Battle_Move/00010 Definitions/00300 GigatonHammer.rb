module Battle
  class Move
    # Gigaton Hammer can't be selected twice in a row
    class GigatonHammer < Basic
      # Get the reason why the move is disabled
      # @param user [PFM::PokemonBattler] user of the move
      # @return [#call] Block that should be called when the move is disabled
      def disable_reason(user)
        return unless user.move_history&.last&.db_symbol == db_symbol

        return proc { @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 911, user, PFM::Text::MOVE[1] => name)) }
      end
    end
    Move.register(:s_gigaton_hammer, GigatonHammer)
  end
end
