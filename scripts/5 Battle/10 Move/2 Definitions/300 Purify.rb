module Battle
  class Move
    # Purify move
    class Purify < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return unless super

        unless targets.any?(&:status?)
          return show_usage_failure(user) && false
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.status?

          @logic.status_change_handler.status_change_with_process(:cure, target, user, self)
        end

        hp = user.max_hp / 2
        logic.damage_handler.heal(user, hp)
      end
    end
    Move.register(:s_purify, Purify)
  end
end
