module Battle
  module Effects
    class Item
      class KingsRock < Item
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if launcher != @target
          return unless skill&.trigger_king_rock? && launcher != target && bchance?(launcher.has_ability?(:serene_grace) ? 0.2 : 0.1, @logic)

          handler.scene.visual.show_item(launcher)
          apply_common_effects_with_fling(handler.scene, target, launcher, skill)
        end

        # Apply the common effects of the item with Fling move effect
        # @param scene [Battle::Scene] battle scene
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def apply_common_effects_with_fling(scene, target, launcher = nil, skill = nil)
          scene.logic.status_change_handler.status_change_with_process(:flinch, target, launcher, skill)
        end
      end

      register(:king_s_rock, KingsRock)
      register(:razor_fang, KingsRock)
    end
  end
end
