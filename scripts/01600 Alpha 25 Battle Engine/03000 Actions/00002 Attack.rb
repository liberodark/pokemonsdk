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

        unless @pursuit_enabled && other.is_a?(Attack) && other.pursuit_enabled
          return -1 if @pursuit_enabled
          return 1 if other.is_a?(Attack) && other.pursuit_enabled
        end

        return (other.roaming_comparison_result(self) == 1 ? -1 : 1) if other.is_a?(Flee) && $wild_battle.is_roaming?(other.target.original)
        return -1 if other.is_a?(Flee) && move.relative_priority > 0
        return 1 unless other.is_a?(Attack)

        attack = Attack.from(other)

        return -1 if @ignore_speed && attack.move.priority(attack.launcher) == @move.priority(@launcher)

        priority_return = attack.move.priority(attack.launcher) <=> @move.priority(@launcher)
        return priority_return if priority_return != 0

        # Stall & LowPriorityItem Procedure
        return 1 if @launcher.has_ability?(:stall) && (attack.launcher.battle_ability_db_symbol != :stall && %i[full_incense lagging_tail].none?(attack.launcher.battle_item_db_symbol))
        return -1 if attack.launcher.has_ability?(:stall) && (@launcher.battle_ability_db_symbol != :stall && %i[full_incense lagging_tail].none?(@launcher.battle_item_db_symbol))

        return 1 if %i[full_incense lagging_tail].any? { |db_symbol| @launcher.hold_item?(db_symbol)} && %i[full_incense lagging_tail].none?(attack.launcher.battle_item_db_symbol)
        return -1 if %i[full_incense lagging_tail].any? { |db_symbol| attack.launcher.hold_item?(db_symbol)} && %i[full_incense lagging_tail].none?(@launcher.battle_item_db_symbol)

        priority_return = mycelium_might_priority(attack)
        return priority_return if priority_return != 0

        trick_room_factor = @scene.logic.terrain_effects.has?(:trick_room) ? -1 : 1
        return (attack.launcher.spd <=> @launcher.spd) * trick_room_factor
      end

      # Get the priority of the move
      # @return [Integer]
      def priority
        return @pursuit_enabled ? 999 : @move.priority
      end

      # Get the target of the move
      # @return [PFM::PokemonBattler, nil]
      def target
        targets = @move.battler_targets(@launcher, @scene.logic).select(&:alive?)
        best_target = targets.select { |battler| battler.position == @target_position && battler.bank == @target_bank }.first
        return best_target if best_target

        best_target = targets.select { |battler| battler.bank == @target_bank }.first
        return best_target || targets.first
      end

      # Execute the action
      def execute
        # Reset flee attempt count
        @scene.battle_info.flee_attempt_count = 0 if @launcher.from_party?
        @move.proceed(@launcher, @target_bank, @target_position)
        @scene.on_after_attack(@launcher, @move)

        dancer_sub_launchers if @move.dance?
      end

      # Function that manages the effect of the dancer ability
      def dancer_sub_launchers
        return if @launcher.effects.has?(:snatched)

        dancers = @scene.logic.all_alive_battlers.select { |battler| battler.has_ability?(:dancer) && battler != @launcher }
        return if dancers.empty?

        dancers = dancers.sort_by(&:spd)
        dancers.each do |dancer|
          next if dancer.dead?
          next if dancer.effects.has?(:out_of_reach_base) || dancer.effects.has?(:flinch)

          @scene.visual.show_ability(dancer)
          @scene.visual.wait_for_animation
          dancer.ability_effect&.activated = true

          if @launcher.bank == dancer.bank && @launcher != target
            @move.dup.proceed(dancer, @target_bank, @target_position)
          elsif @launcher.bank != dancer.bank && @launcher != target && @move.db_symbol != :lunar_dance
            @move.dup.proceed(dancer, @launcher.bank, @launcher.position)
          else
            @move.dup.proceed(dancer, dancer.bank, dancer.position)
          end

          dancer.ability_effect&.activated = false
        end
      end

      # Define which Pokémon should go first if either of them or both have the ability Mycelium Might.
      # @param attack [Battle::Actions::Attack]
      # @return [Integer]
      def mycelium_might_priority(attack)
        return 0 if @launcher.battle_ability_db_symbol != :mycelium_might && attack.launcher.battle_ability_db_symbol != :mycelium_might

        return 1 if @launcher.has_ability?(:mycelium_might) && attack.launcher.battle_ability_db_symbol != :mycelium_might && @move.status?
        return -1 if attack.launcher.has_ability?(:mycelium_might) && launcher.battle_ability_db_symbol != :mycelium_might && attack.move.status?

        return 0
      end

      # Action describing the action forced by Encore
      class Encore < Attack
        # Execute the action
        def execute
          @move.forced_next_move_decrease_pp = true
          super
          @move.forced_next_move_decrease_pp = false
          if @move.pp <= 0 && (effect = @launcher.effects.get(:encore))
            effect.kill
          end
        end
      end
    end
  end
end
