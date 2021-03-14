module Battle
  class Move
    # Class managing Rest
    class Rest < Move
      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return true if super

        if target.has_ability?(:insomnia) || target.has_ability?(:vital_spirit)
          scene.visual.show_ability(target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 451, target))
          return true
        elsif target.hp == target.max_hp
          scene.display_message_and_wait(parse_text_with_pokemon(19, 451, target))
          return true
        elsif target.effects.has?(:heal_block)
          txt = parse_text_with_pokemon(19, 893, user, '[VAR PKNICK(0000)]' => user.given_name, '[VAR MOVE(0001)]' => name)
          scene.display_message_and_wait(txt)
          return true
        end
        return false
      end

      # Function that deals the status condition to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_status(user, actual_targets)
        actual_targets.each do |target|
          scene.visual.show_info_bar(target)
          target.status_sleep(true, target.has_ability?(:early_bird) ? 1 : 2)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 306, target))
          hp = target.max_hp
          scene.visual.show_hp_animations([target], [hp])
          scene.display_message_and_wait(parse_text_with_pokemon(19, 638, target))
          if target.asleep? && target.hold_item?(:chesto_berry)
            logic.status_change_handler.status_change(:cure, target)
            logic.item_change_handler.change_item(:none, true, target)
          end
        end
      end
    end
    Move.register(:s_rest, Rest)
  end
end
