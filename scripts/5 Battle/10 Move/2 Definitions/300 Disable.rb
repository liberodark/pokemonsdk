module Battle
  class Move
    # Disable move
    class Disable < Move
      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return true if super
        return failure_message unless target.move_history.last
        return failure_message if target.effects.has?(:disable)

        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          move = target.move_history&.last&.original_move
          next unless move

          message = parse_text_with_pokemon(19, 592, target, PFM::Text::MOVE[1] => move.name)
          target.effects.add(Effects::Disable.new(@logic, target, move))
          @scene.display_message_and_wait(message)
        end
      end

      private

      # Display failure message
      # @return [Boolean] true for blocking
      def failure_message
        @logic.scene.display_message_and_wait(parse_text(18, 74))
        return true
      end
    end

    Move.register(:s_disable, Disable)
  end
end
