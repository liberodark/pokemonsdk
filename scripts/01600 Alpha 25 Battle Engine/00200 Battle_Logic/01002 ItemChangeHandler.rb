module Battle
  class Logic
    # Handler responsive of answering properly item changes requests
    class ItemChangeHandler < ChangeHandlerBase
      include Hooks

      # Function that change the item held by a Pokemon
      # @param db_symbol [Symbol, :none] Symbol ID of the item
      # @param overwrite [Boolean] if the actual item held should be overwritten
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def change_item(db_symbol, overwrite, target, launcher = nil, skill = nil)
        exec_hooks(ItemChangeHandler, :pre_item_change, binding)
        target.battle_item = db_symbol == :none ? 0 : GameData::Item[db_symbol].id
        target.item_holding = target.battle_item if overwrite
        exec_hooks(ItemChangeHandler, :post_item_change, binding)
      rescue Hooks::ForceReturn => e
        return e.data
      end

      class << self
        # Function that registers a pre_item_change hook
        # @param reason [String] reason of the pre_item_change registration
        # @yieldparam handler [ItemChangeHandler]
        # @yieldparam db_symbol [Symbol] Symbol ID of the item
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        # @yieldreturn [:prevent, nil] :prevent if the item change cannot be applied
        def register_pre_item_change_hook(reason)
          Hooks.register(ItemChangeHandler, :pre_item_change, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:db_symbol),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
            force_return(false) if result == :prevent
          end
        end

        # Function that registers a post_item_change hook
        # @param reason [String] reason of the post_item_change registration
        # @yieldparam handler [ItemChangeHandler]
        # @yieldparam db_symbol [Symbol] Symbol ID of the item
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        def register_post_item_change_hook(reason)
          Hooks.register(ItemChangeHandler, :post_item_change, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:db_symbol),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
          end
        end
      end
    end

    # Register the Unburden ablility
    ItemChangeHandler.register_post_item_change_hook('PSDK item change post: Unburden') do |handler, db_symbol, target|
      next if db_symbol != :none || target.ability_db_symbol != :unburden

      if (st_ch = handler.logic.stat_change_handler).stat_increasable?(:spd, target)
        handler.scene.visual.show_ability(target)
        st_ch.stat_change(:spd, 1, target)
      end
      st_ch.reset_prevention_reason
    end

    # Register the Iron Ball addition
    ItemChangeHandler.register_post_item_change_hook('PSDK item change post: Iron Ball') do |handler, db_symbol, target|
      next if db_symbol != :iron_ball || !target.battle_effect.has_telekinesis_effect?

      handler.scene.display_message(parse_text_with_pokemon(19, 1149, target))
      target.battle_effect.apply_telekinesis(0)
    end
  end
end
