module Battle
  class Move
    # class managing Fake Out move
    class UpperHand < BasicWithSuccessfulEffect
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if targets.any? { |target| logic.battler_attacks_after?(user, target) || invalid_move?(target) }
          show_usage_failure(user)
          return false
        end

        return true
      end

      # Function that tells if the target is using an invalid move: either status, or not priority
      # @return [Boolean]
      def invalid_move?(target)
        # @type [Array<Actions::Attack>]
        attacks = logic.actions.select { |action| action.is_a?(Actions::Attack) }
        return true unless (move = attacks.find { |action| action.launcher == target }&.move)

        return move&.status? || move&.relative_priority < 1
      end
    end
    Move.register(:s_upper_hand, UpperHand)
  end
end
