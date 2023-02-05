module Battle
  class Move
    # Move that has a big recoil when fails
    class HighJumpKick < Basic
      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity, :pp
      def on_move_failure(user, targets, reason)
        return if [:usable_by_user, :pp].include?(reason)

        return crash_procedure(user)
      end

      # Define the crash procedure when the move isn't able to connect to the target
      # @param user [PFM::PokemonBattler] user of the move
      def crash_procedure(user)
        hp = user.max_hp / 2
        scene.visual.show_hp_animations([user], [-hp])
        scene.display_message_and_wait(parse_text_with_pokemon(19, 908, user))
      end
    end
    Move.register(:s_jump_kick, HighJumpKick)
  end
end
