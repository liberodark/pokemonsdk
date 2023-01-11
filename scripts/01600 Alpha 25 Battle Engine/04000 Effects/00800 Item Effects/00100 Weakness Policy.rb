module Battle
  module Effects
    class Item
      class WeaknessPolicy < Item
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return unless skill&.super_effective?

          handler.scene.visual.show_item(target)
          handler.logic.stat_change_handler.stat_change_with_process(:atk, 2, target)
          handler.logic.stat_change_handler.stat_change_with_process(:ats, 2, target)
          handler.logic.item_change_handler.change_item(:none, true, target)
        end
      end
      register(:weakness_policy, WeaknessPolicy)
    end
  end
end
