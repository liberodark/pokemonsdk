module Battle
  module Effects
    class Item
      class LightBall < Item
        # Apply the common effects of the item with Fling move effect
        # @param scene [Battle::Scene] battle scene
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def apply_common_effects_with_fling(scene, target, launcher = nil, skill = nil)
          scene.logic.status_change_handler.status_change_with_process(:paralysis, target, launcher, skill)
        end

        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 2 if @target.db_symbol == :pikachu

          return super
        end
        alias ats_modifier atk_modifier
      end

      register(:light_ball, LightBall)
    end
  end
end
