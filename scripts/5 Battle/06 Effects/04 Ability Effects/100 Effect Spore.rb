module Battle
  module Effects
    class Ability
      class EffectSpore < Ability
        # @return [Hash{Symbol => Symbol}]
        CAN_BE_METHODS = {
          poison: :can_be_poisoned?,
          sleep: :can_be_asleep?,
          paralysis: :can_be_paralyzed?
        }

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless launcher&.alive? && skill&.made_contact?
          return if launcher.has_ability?(:overcoat)
          return if launcher.type_grass?
          return if launcher.hold_item?(:safety_goggles)
          return if (n = handler.logic.generic_rng.rand(10)) > 2 # ~30%

          status = %i[poison sleep paralysis][n]
          return unless launcher.send(CAN_BE_METHODS[status])

          handler.scene.visual.show_ability(target)
          handler.logic.status_change_handler.status_change_with_process(status, launcher, target)
        end
      end
      register(:effect_spore, EffectSpore)
    end
  end
end
