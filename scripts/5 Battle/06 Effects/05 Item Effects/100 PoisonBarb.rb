module Battle
  module Effects
    class Item
      class PoisonBarb < Item
        # Give the move base power mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def base_power_multiplier(user, target, move)
          return 1 if user != @target
          return 1 unless move.type_poison?

          return 1.2
        end

        # Apply the common effects of the item with Fling move effect
        # @param scene [Battle::Scene] battle scene
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def apply_common_effects_with_fling(scene, target, launcher = nil, skill = nil)
          scene.logic.status_change_handler.status_change(:poison, target, launcher, skill)
        end
      end

      register(:poison_barb, PoisonBarb)
    end
  end
end
