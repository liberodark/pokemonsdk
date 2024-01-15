module Battle
  module Effects
    class Ability
      class BattleBond < Ability
        # New version of the Greninja ability (9G+)
        BATTLE_BOND_GEN_NINE = false
        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return new_ability_effect(handler, hp, target, launcher, skill) if BATTLE_BOND_GEN_NINE

          return form_calibrate(handler, hp, target, launcher, skill) if launcher == @target
          return revert_original_form(handler, hp, target, launcher, skill) if target == @target
        end

        private

        # @type [Array<Symbol>]
        STATS_TO_INCREASE = %i[atk ats spd]
        # Function handling the new ability effect since 9G
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def new_ability_effect(handler, hp, target, launcher, skill)
          return if target == @target || launcher != @target
          return if launcher.ability_used
          return if STATS_TO_INCREASE.none? { |stat| handler.logic.stat_change_handler.stat_increasable?(stat, launcher) }

          handler.scene.visual.show_ability(launcher)
          handler.scene.visual.wait_for_animation

          STATS_TO_INCREASE.each do |stat|
            handler.logic.stat_change_handler.stat_change_with_process(stat, 1, launcher)
          end

          launcher.ability_used = true
        end

        # Function to manage form after knocking out a pokemon 
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def form_calibrate(handler, hp, target, launcher, skill)
          return unless launcher.form == 0
          return if launcher.ability_used

          handler.scene.visual.show_ability(launcher)
          handler.scene.visual.wait_for_animation
          launcher.form_calibrate(:battle)
          handler.scene.visual.show_switch_form_animation(launcher)
        end

        # Function to restore the original form after being knocked out
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def revert_original_form(handler, hp, target, launcher, skill)
          return if target.form == 0

          target.form_calibrate(:base)
          handler.scene.visual.show_switch_form_animation(target)
          target.ability_used = true
        end
      end
      register(:battle_bond, BattleBond)
    end
  end
end
