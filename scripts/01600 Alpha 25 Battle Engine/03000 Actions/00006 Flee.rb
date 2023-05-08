module Battle
  module Actions
    # Class describing the Flee action
    class Flee < Base
      # Get the pokemon trying to flee
      # @return [PFM::PokemonBattler]
      attr_reader :target
      # Create a new flee action
      # @param scene [Battle::Scene]
      # @param target [PFM::PokemonBattler]
      def initialize(scene, target)
        super(scene)
        @target = target
      end

      # Compare this action with another
      # @param other [Base] other action
      # @return [Integer]
      def <=>(other)
        return roaming_comparison_result(attack) if $wild_battle.is_roaming?(target.original) && other.is_a?(Attack) && (attack = Attack.from(other))
        return 1 if other.is_a?(Attack) && Attack.from(other).move.relative_priority > 0

        return -1
      end

      # Constant telling the priority applied to a Fleeing action for a Roaming Pokemon
      # @return [Integer]
      PRIORITY_ROAMING_FLEE = -7

      # Give the comparison result for a Roaming Pokemon
      # @param attack [Attack] other action
      # @return [Integer]
      # @note Based on Gen 5 mechanism as Gen 6 mechanism isn't a real Roaming feature
      # In Gen 5, a Roaming Pokemon trying to escape has a Priority of -7
      def roaming_comparison_result(attack)
        return 1 if attack.move.relative_priority > PRIORITY_ROAMING_FLEE
        return -1 if attack.move.relative_priority < PRIORITY_ROAMING_FLEE
        return 1 if target.spd < attack.launcher.spd
        return [-1, 1].sample if target.spd == attack.launcher.spd
        return -1 if target.spd > attack.launcher.spd
      end

      # Execute the action
      # @param from_scene [Boolean] if the action was triggered during the player choice
      def execute(from_scene = false)
        if from_scene
          execute_from_scene
        elsif @scene.logic.switch_handler.can_switch?(@target)
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 767, @target))
          @scene.logic.battle_result = @target.bank == 0 ? 1 : 3
          @scene.next_update = :battle_end
        end
      end

      private

      # Execute the action if the pokemon is from party
      def execute_from_scene
        result = @scene.logic.flee_handler.attempt(@target.position)
        if result == :success
          @scene.logic.battle_result = 1
          @scene.next_update = :battle_end
        end
      end
    end
  end
end
