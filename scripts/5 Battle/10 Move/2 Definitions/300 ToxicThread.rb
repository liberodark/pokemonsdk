module Battle
  class Move
    class ToxicThread < Move
      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        cannot_stat = battle_stage_mod.all? { |stage| stage.count == 0 || !@logic.stat_change_handler.stat_decreasable?(stage.stat, target, user, self) }
        cannot_status = status_effects.all? { |status| status.luck_rate == 0 || !@logic.status_change_handler.status_appliable?(status.status, target, user, self) }
        return failure_message if cannot_stat && cannot_status

        return super
      end

      private

      # Display failure message
      # @return [Boolean] true for blocking
      def failure_message
        logic.scene.display_message_and_wait(parse_text(18, 74))
        return true
      end
    end
    Move.register(:s_toxic_thread, ToxicThread)
  end
end
