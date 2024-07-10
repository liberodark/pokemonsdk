module Battle
  class Move
    # Move that inflict leech seed to the ennemy
    class CoreEnforcer < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.any? { |target| !target.effects.has?(:ability_suppressed) }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:ability_suppressed)

          launchers = logic.turn_actions.map { |action| action.instance_variable_get(:@launcher) }
          launchers.first == user ? target.effects.add(Effects::AbilitySuppressed.new(@logic, target)) : next
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 565, target))
        end
      end
    end
    Move.register(:s_core_enforcer, CoreEnforcer)
  end
end
