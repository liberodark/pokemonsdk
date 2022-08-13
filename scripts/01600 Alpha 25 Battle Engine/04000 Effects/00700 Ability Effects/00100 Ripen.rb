module Battle
  module Effects
    class Ability
      class Ripen < Ability
        # Function called when a pre_item_change is checked
        # @param handler [Battle::Logic::ItemChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the item
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_pre_item_change(handler, db_symbol, target, launcher, skill)
          return unless target.hold_berry?(target.battle_item_db_symbol)
          return if target.effects.has?(:item_burnt) || target.effects.has?(:item_stolen)

          handler.scene.visual.show_ability(target)
        end
      end
      register(:ripen, Ripen)
    end
  end
end
