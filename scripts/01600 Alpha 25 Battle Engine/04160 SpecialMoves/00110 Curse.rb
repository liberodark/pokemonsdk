module Battle
  class Move
    # Class managing Curse
    class Curse < Move
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        if user.type_ghost?
          # TODO: Add Malediction subanimation for the recoil
          hp = user.max_hp / 2
          scene.visual.show_hp_animations([user], [-hp])
          actual_targets.each do |target|
            target.effects.add(Effects::Curse.new(@logic, target))
            scene.display_message_and_wait(parse_text_with_pokemon(19, 1070, user,
                                                                  '[VAR PKNICK(0000)]' => user.given_name,
                                                                  '[VAR PKNICK(0001)]' => target.given_name))
          end
        else
          @logic.stat_change_handler.stat_change_with_process(:spd, -1, user, user, self)
          @logic.stat_change_handler.stat_change_with_process(:atk, 1, user, user, self)
          @logic.stat_change_handler.stat_change_with_process(:dfe, 1, user, user, self)
        end
      end

      def effect_working?(user, actual_targets)
        return true
      end
    end
    Move.register(:s_curse, Curse)
  end
end
