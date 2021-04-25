#Makes user lost 1/2 of Max HP (rounded down) and maximizes attack to +6.
#If user is below 1/2 it won't work
#If user has contrary lower to -6.
module Battle
    class Move
      class BellyDrum < Move
        def move_usable_by_user(user, targets)
          hp = (user.max_hp / 2).floor
          can_change_atk = logic.stat_change_handler.stat_increasable?(:atk, user)
          if user.hp < hp || !can_change_atk
            show_usage_failure(user)
            return false
          end
          return true
        end
  
        def deal_effect(user, actual_targets)
          hp = (user.max_hp / 2).floor
          scene.visual.show_hp_animations([user], [-hp])
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1255, user))
          logic.stat_change_handler.stat_change_with_process(:atk, 12, user)
        end
      end
      Move.register(:s_bellydrum, BellyDrum)
    end
  end