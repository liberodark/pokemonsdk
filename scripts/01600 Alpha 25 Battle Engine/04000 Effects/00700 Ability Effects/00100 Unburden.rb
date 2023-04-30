module Battle
  module Effects
    class Ability
      class Unburden < Ability
        # Give the speed modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def spd_modifier
          return 2 if @target.effects.has?(:item_stolen) || @target.effects.has?(:item_burnt)
          return 2 if @target.item_consumed

          return @boost_enabled ? 2 : 1
        end

        # Function called when a post_item_change is checked
        # @param handler [Battle::Logic::ItemChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the item
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_item_change(handler, db_symbol, target, launcher, skill)
          @boost_enabled = false
          return unless db_symbol == :none

          @boost_enabled = true
          handler.scene.visual.show_ability(@target)
        end

        # Reset the boost when leaving battle
        def reset
          @boost_enabled = false
        end
      end
      register(:unburden, Unburden)
    end
  end
end

Hooks.register(PFM::PokemonBattler, :on_reset_states, 'PSDK reset Unburden') do
  ability_effect.reset if ability_effect.is_a?(Battle::Effects::Ability::Unburden)
end
