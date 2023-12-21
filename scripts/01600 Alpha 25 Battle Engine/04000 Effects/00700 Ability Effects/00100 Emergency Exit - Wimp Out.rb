module Battle
  module Effects
    class Ability
      class EmergencyExit < Ability
        # Create a new Emergency Exit effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @damage_dealt = 0
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return if target.ability_used
          return if target.hp_rate > 0.5 || target.effects.has?(&:out_of_reach?)
          return if skill_prevention?(hp, skill) || item_prevention?(target)
          return if launcher.has_ability?(:sheer_force) && launcher.ability_effect&.activated? 
          return if handler.logic.switch_request.any? { |request| request[:who] == target }     

          @damage_dealt = 0
          if @logic.battle_info.trainer_battle?
            return unless handler.logic.can_battler_be_replaced?(target)

            target.ability_used = true
            handler.scene.visual.show_ability(target)
            handler.scene.visual.wait_for_animation
            
            @logic.actions.reject! { |a| a.is_a?(Actions::Attack) && a.launcher == target }
            handler.logic.switch_request << { who: target }
          else          
            handler.scene.visual.show_ability(target)
            @battler_s = handler.scene.visual.battler_sprite(target.bank, target.position)
            @battler_s.flee_animation
            @logic.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 767, target))
            @logic.battle_result = 1
          end
        end

        # Check if a move will prevents the ability from triggering
        # @param hp [Integer] number of hp (damage) dealt
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def skill_prevention?(hp, skill)
          return false unless skill
          return true if skill.force_switch? || skill.be_method == :s_sky_drop

          @damage_dealt += hp
          
          return true if skill.is_a?(Battle::Move::Basic::MultiHit) && !skill.last_hit?
          return false if (target.hp + @damage_dealt) > target.max_hp / 2
        end

        # Check if an item effect prevents the ability from triggering
        # @param target [PFM::PokemonBattler]
        # @return [Boolean]
        def item_prevention?(target)
          return true if target.hold_item?(:eject_button)
          return false unless target.hold_berry?(target.item_db_symbol)

          hp_healed = target.item_effect&.hp_healed || 0
          return (target.hp + hp_healed) > target.max_hp / 2
        end
      end
      register(:emergency_exit, EmergencyExit)
      register(:wimp_out, EmergencyExit)
    end
  end
end