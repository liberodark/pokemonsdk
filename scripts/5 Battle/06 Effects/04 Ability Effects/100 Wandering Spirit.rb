module Battle
  module Effects
    class Ability
      class WanderingSpirit < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless skill&.direct? && launcher&.alive? && !launcher.has_ability?(:long_reach)
          return if launcher.ability_effect.is_a?(Battle::Effects::Ability::WanderingSpirit)
          return unless handler.logic.ability_change_handler.can_change_ability?(launcher, target)
          return unless handler.logic.ability_change_handler.can_change_ability?(target, launcher)

          handler.logic.ability_change_handler.apply_ability_swap(target, launcher)
        end
        alias on_post_damage_death on_post_damage
      end
      register(:wandering_spirit, WanderingSpirit)
    end
  end
end
