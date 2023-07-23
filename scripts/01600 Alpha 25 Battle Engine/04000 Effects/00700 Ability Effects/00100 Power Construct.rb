module Battle
  module Effects
    class Ability
      class PowerConstruct < Ability
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead? || @target.form == 3 || @target.hp_rate >= 0.5

          max_hp_pre_construct = @target.max_hp

          @target.form_calibrate(:battle)
          scene.visual.show_ability(@target)
          scene.visual.show_switch_form_animation(@target)
          scene.display_message_and_wait(parse_text(60, 362))

          @target.hp += @target.max_hp - max_hp_pre_construct
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          @target.form_calibrate(:base)
        end
      end
      register(:power_construct, PowerConstruct)
    end
  end
end
