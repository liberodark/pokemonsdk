module Battle
  module Actions
    # Class describing the Attack Action
    class Attack < Base
      # Get the move of this action
      # @return [Battle::Move]
      attr_reader :move
      # Get the user of this move
      # @return [PFM::PokemonBattler]
      attr_reader :launcher
      # Tell if pursuit on this action is enabled
      # @return [Boolean]
      attr_accessor :pursuit_enabled
      # Tell if this action can ignore speed of the other pokemon
      # @return [Boolean]
      attr_accessor :ignore_speed
      # Create a new attack action
      # @param scene [Battle::Scene]
      # @param move [Battle::Move]
      # @param launcher [PFM::PokemonBattler]
      # @param target_bank [Integer] bank the move aims
      # @param target_position [Integer] position the move aims
      def initialize(scene, move, launcher, target_bank, target_position)
        super(scene)
        @move = move
        @launcher = launcher
        @target_bank = target_bank
        @target_position = target_position
        @pursuit_enabled = false
        @ignore_speed = false
      end

      # Compare this action with another
      # @param other [Base] other action
      # @return [Integer]
      def <=>(other)
        return 1 if other.is_a?(HighPriorityItem)
        return -1 if @pursuit_enabled
        return 1 unless other.is_a?(Attack)

        attack = Attack.from(other)
        return -1 if @ignore_speed && attack.move.priority == @move.priority

        priority_return = attack.move.priority <=> @move.priority
        return priority_return if priority_return != 0

        return attack.launcher.spd <=> @launcher.spd # <= Invert result here if Trick Room is enabled!!
      end

      # Get the priority of the move
      # @return [Integer]
      def priority
        return @pursuit_enabled ? 999 : @move.priority
      end

      # Get the target of the move
      # @return [PFM::PokemonBattler, nil]
      def target
        @move.battler_targets(@launcher, @scene.logic).select(&:alive?).first
      end

      # Execute the action
      def execute
        # Reset flee attempt count
        @logic.battle_info.flee_attempt_count = 0 if @launcher.from_party?
        @move.proceed(@launcher, @target_bank, @target_position)
      end
    end
  end
end
