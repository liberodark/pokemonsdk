module Battle
  module Effects
    class Ability
      class ThermalExchange < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return unless skill&.type_fire?
            
          handler.scene.visual.show_ability(target)
          handler.scene.visual.wait_for_animation
          handler.logic.stat_change_handler.stat_change_with_process(:atk, 1, target)
        end

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target != @target || target.effects.has?(:substitute)
          return unless status == :burn
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
            handler.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 270, target))
          end
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return unless @target.alive? && @target.burn?

          logic.status_change_handler.status_change(:cure, @target)
        end
      end
      register(:thermal_exchange, ThermalExchange)
    end
  end
end