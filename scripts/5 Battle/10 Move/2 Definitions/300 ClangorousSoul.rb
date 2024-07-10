module Battle
  class Move
    class ClangorousSoul < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        can_change_atk = logic.stat_change_handler.stat_increasable?(:atk, user)
        can_change_ats = logic.stat_change_handler.stat_increasable?(:ats, user)
        can_change_dfe = logic.stat_change_handler.stat_increasable?(:dfe, user)
        can_change_dfs = logic.stat_change_handler.stat_increasable?(:dfs, user)
        can_change_spd = logic.stat_change_handler.stat_increasable?(:spd, user)

        stat_changeable = can_change_atk || can_change_ats || can_change_dfe || can_change_dfs || can_change_spd
        if user.hp_rate <= 0.33 || !stat_changeable
          show_usage_failure(user)
          return false
        end
        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        hp = (user.max_hp / 3).floor
        scene.visual.show_hp_animations([user], [-hp])
      end
    end
    Move.register(:s_clangorous_soul, ClangorousSoul)
  end
end
