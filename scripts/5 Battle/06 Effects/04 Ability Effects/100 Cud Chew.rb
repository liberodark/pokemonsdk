module Battle
  module Effects
    class Ability
      class CudChew < Ability
        # Function called when a pre_item_change is checked
        # @param handler [Battle::Logic::ItemChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the item
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the item change cannot be applied
        def on_pre_item_change(handler, db_symbol, target, launcher, skill)
          target_item = target.battle_item_db_symbol

          return unless @target == target
          return unless data_item(target_item)&.socket == 4
          return unless target.consumed_item == target_item

          target.effects.add(Effects::CudChewEffect.new(handler.logic, target, turn_count, target_item))
        end

        # Return the turn countdown before the effect proc (including the current one)
        # @return [Integer]
        def turn_count
          return 2
        end
      end
      register(:cud_chew, CudChew)
    end
  end
end
