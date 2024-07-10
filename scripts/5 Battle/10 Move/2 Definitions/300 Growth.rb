module Battle
  class Move
    # Class describing a self stat move (damage + potential status + potential stat to user)
    class Growth < SelfStat
      def deal_stats(user, actual_targets)
        battle_stage_mod.each do |stage|
          if $env.sunny? || $env.hardsun?
            @logic.stat_change_handler.stat_change_with_process(stage.stat, 2, user, user, self)
          else
            @logic.stat_change_handler.stat_change_with_process(stage.stat, 1, user, user, self)
          end
        end
      end
    end
    Move.register(:s_growth, Growth)
  end
end
