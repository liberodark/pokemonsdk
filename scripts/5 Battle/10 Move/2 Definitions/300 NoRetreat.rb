module Battle
  class Move
    class NoRetreat < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        return show_usage_failure(user) && false if user.effects.has?(:no_retreat)

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.effects.add(Effects::NoRetreat.new(logic, user, user, self)) if can_be_affected?(user)
      end

      # Check if the user can be affected by the effect
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean]
      def can_be_affected?(user)
        return false if user.type_ghost?
        return false if user.effects.has?(:cantswitch)

        return true
      end
    end
    Move.register(:s_no_retreat, NoRetreat)
  end
end
