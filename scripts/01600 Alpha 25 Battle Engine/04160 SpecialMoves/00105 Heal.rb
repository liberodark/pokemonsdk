module Battle
  class Move
    # Class describing a heal move
    class HealMove < Move
      # Function that return the immunity
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      def target_immune?(user, target)
        return true if super

        return db_symbol == :heal_pulse && target.effects.has?(:substitute)
      end

      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return true if super

        if target.effects.has?(:heal_block)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 890, target))
          return true
        elsif target.hp == target.max_hp
          scene.display_message_and_wait(parse_text_with_pokemon(19, 896, target))
          return true
        end
        return false
      end

      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          hp = target.max_hp / 2
          hp = hp * 3 / 2 if pulse? && user.has_ability?(:mega_launcher)
          scene.visual.show_hp_animations([target], [hp])
          scene.display_message_and_wait(parse_text_with_pokemon(19, 387, target))
        end
      end

      # Tell that the move is a heal move
      def heal?
        return true
      end
    end

    Move.register(:s_heal, HealMove)
  end
end
