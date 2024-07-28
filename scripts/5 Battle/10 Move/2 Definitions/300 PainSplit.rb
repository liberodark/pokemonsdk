module Battle
  class Move
    # Move that share HP between targets
    class PainSplit < Move
      # Check if the move bypass chance of hit and cannot fail
      # @param _user [PFM::PokemonBattler] user of the move
      # @param _target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def bypass_chance_of_hit?(_user, _target)
        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        hp_total = 0
        actual_targets = [user].concat(actual_targets)
        actual_targets.each { |target| hp_total += target.effects.has?(:substitute) ? target.effects.get(:substitute).hp : target.hp }
        average_hp = (hp_total / actual_targets.size).to_i
        scene.display_message_and_wait(message)
        actual_targets.each { |target| adjust_hp(target, average_hp) }
      end

      # Get the message
      # @return [String] the text parsed and ready to be displayed
      def message
        return parse_text(18, 117)
      end

      # Adjusts the HP of the target based on the calculated average HP
      # @param target [PFM::PokemonBattler]
      # @param average_hp [Integer]
      def adjust_hp(target, average_hp)
        if target.effects.has?(:substitute) && !authentic?
          target.effects.get(:substitute).hp = average_hp.clamp(1, target.effects.get(:substitute).max_hp)
        else
          hp_difference = average_hp - target.hp
          hp_difference > 0 ? logic.damage_handler.heal(target, hp_difference) : logic.damage_handler.damage_change(hp_difference.abs, target)
        end
      end
    end

    Move.register(:s_pain_split, PainSplit)
  end
end
