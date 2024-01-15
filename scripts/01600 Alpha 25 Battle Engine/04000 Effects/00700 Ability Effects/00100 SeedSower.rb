module Battle
  module Effects
    class Ability
      class SeedSower < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == @target
          return unless skill
          return if handler.logic.field_terrain_effect.grassy?

          turn_count = target.hold_item?(:terrain_extender) ? 8 : 5
          handler.logic.fterrain_change_handler.fterrain_change(:grassy_terrain, turn_count)
        end
      end
      register(:seed_sower, SeedSower)
    end
  end
end
