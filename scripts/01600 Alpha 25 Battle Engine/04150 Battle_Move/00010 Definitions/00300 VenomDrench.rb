module Battle
  class Move
    class VenomDrench < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        
        if targets.none? { |target| target.poisoned? || target.toxic? }
          return show_usage_failure(user) && false
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.poisoned? || target.toxic?

          logic.stat_change_handler.stat_change_with_process(:atk, -1, target, user)
          logic.stat_change_handler.stat_change_with_process(:ats, -1, target, user)
          logic.stat_change_handler.stat_change_with_process(:spd, -1, target, user)
        end
      end
    end
    Move.register(:s_venom_drench, VenomDrench)
  end
end
