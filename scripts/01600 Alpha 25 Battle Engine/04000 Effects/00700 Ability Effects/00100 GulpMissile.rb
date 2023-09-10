module Battle
  module Effects
    class Ability
      class GulpMissile < Ability
        FORM_ARROKUDA = :arrokuda
        FORM_PIKACHU = :pikachu
        BASE_FORM = :base
        TRIGGER_SKILLS = %i[surf waterfall]

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          catch_prey(handler, hp, target, launcher, skill) if launcher == @target
          spit_out_prey(handler, hp, target, launcher, skill) if target == @target
        end

        private

        # Catch a different prey according to the current HP
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def catch_prey(handler, hp, target, launcher, skill)
          return unless @target.form == 0 && TRIGGER_SKILLS.include?(skill.db_symbol)

          @target.form_calibrate(@target.hp_rate > 0.5 ? FORM_ARROKUDA : FORM_PIKACHU)
          handler.scene.visual.show_switch_form_animation(@target)
        end

        # Spit out the prey, causing damage and additional effects depending on the form
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def spit_out_prey(handler, hp, target, launcher, skill)
          return if @target.form == 0 || skill.status?

          damages = (launcher.max_hp / 4).clamp(1, Float::INFINITY)
          handler.scene.visual.show_ability(@target)
          handler.scene.visual.show_hp_animations([launcher], [-damages]) unless launcher.has_ability?(:magic_guard)

          case @target.form
          when 1
            handler.logic.stat_change_handler.stat_change_with_process(:dfe, -1, launcher, launcher.has_ability?(:mirror_armor) ? target : nil)
          else
            handler.logic.status_change_handler.status_change_with_process(:paralysis, launcher, target)
          end

          @target.form_calibrate(BASE_FORM)
          handler.scene.visual.show_switch_form_animation(@target)
        end
      end
      register(:gulp_missile, GulpMissile)
    end
  end
end

