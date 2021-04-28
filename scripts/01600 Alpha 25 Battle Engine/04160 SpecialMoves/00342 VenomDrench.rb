#If enemy is poisoned it will lose atk, spatk, and speed by one stage.
module Battle
    class Move
      class VenomDrench < Move
        def move_usable_by_user(user, targets)
          targets.each do |target|
            if target.poisoned?
              return true
            else
              show_usage_failure(user)
              return false
            end
          end
        end
  
        def deal_effect(user, actual_targets)
          actual_targets.each do |target|
            logic.stat_change_handler.stat_change_with_process(:atk, -1, target)
            logic.stat_change_handler.stat_change_with_process(:ats, -1, target)
            logic.stat_change_handler.stat_change_with_process(:spd, -1, target)
          end
        end
      end
      Move.register(:s_venomdrench, VenomDrench)
    end
  end