module Battle
  module Effects
    class Ability
      class WindRider < Ability
        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_prevention_target(user, target, move)
          return false if target != @target
          return false unless move&.wind_attack?
          return false unless user&.can_be_lowered_or_canceled?

          trigger_effect
          return true
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless logic.current_action.is_a?(Actions::Attack)
          return unless battlers.include?(@target)
          return if @target.dead?

          move = logic.current_action&.move
          return unless move&.db_symbol == :tailwind
          return if logic.foes_of(@target).include?(logic.current_action.launcher)
          return unless logic.current_action.launcher.successful_move_history.last.current_turn?

          trigger_effect
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          return unless handler.logic.bank_effects[@target.bank].has?(:tailwind)

          trigger_effect
        end

        # Function grouping the actions related to Wind Rider's activation
        def trigger_effect
          @logic.scene.visual.show_ability(@target)
          @logic.scene.visual.wait_for_animation
          @logic.stat_change_handler.stat_change_with_process(:atk, 1, @target)
        end
      end
      register(:wind_rider, WindRider)
    end
  end
end
