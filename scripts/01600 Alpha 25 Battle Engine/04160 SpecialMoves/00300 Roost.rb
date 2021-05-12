module Battle
  class Move
    class Roost < HealMove
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          hp = target.max_hp / 2
          scene.visual.show_hp_animations([target], [hp])
          scene.display_message_and_wait(parse_text_with_pokemon(19, message_id, target))
          target.effects.add(Effects::Roost.new(@logic, target, turn_count))
        end
      end

      # ID of the message
      # @return Integer
      def message_id
        return 387
      end

      # Return the number of turns the effect works
      # @return Integer
      def turn_count
        return 1
      end
    end
    Move.register(:s_roost, Roost)
  end
end
