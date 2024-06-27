module Battle
  module Effects
    class Ability
      class WindPower < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == @target
          return unless skill&.wind_attack? && launcher

          @target.effects.add(create_effect(@target))
          handler.scene.visual.show_ability(@target)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 664, @target))
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless logic.current_action.is_a?(Actions::Attack)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if @target.effects.has?(:charge)

          move = logic.current_action&.move
          return unless move&.db_symbol == :tailwind
          return if logic.foes_of(@target).include?(logic.current_action.launcher)
          return unless logic.current_action.launcher.successful_move_history.last.current_turn?

          target.effects.add(create_effect(@target))
          scene.visual.show_ability(@target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 664, @target))
        end

        # Create the effect
        # @param target [PFM::PokemonBattler] expected target
        # @return [Effects::EffectBase]
        def create_effect(target)
          Effects::Charge.new(@logic, target, 2)
        end
      end
      register(:wind_power, WindPower)
    end
  end
end
