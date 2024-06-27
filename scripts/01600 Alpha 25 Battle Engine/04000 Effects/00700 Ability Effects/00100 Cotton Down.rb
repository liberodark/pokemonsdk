module Battle
  module Effects
    class Ability
      class CottonDown < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless skill && launcher&.alive?

          if handler.logic.stat_change_handler.stat_decreasable?(:spd, launcher)
            handler.scene.visual.show_ability(target)
            handler.logic.stat_change_handler.stat_change_with_process(:spd, -1, launcher, handle_mirror_armor_effect(launcher, target))
          end
        end

        private

        # Handle the mirror armor effect (special case)
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @return [PFM::PokemonBattler, nil]
        def handle_mirror_armor_effect(launcher, target)
          return launcher.has_ability?(:mirror_armor) ? target : nil
        end
      end

      register(:cotton_down, CottonDown)
    end
  end
end
