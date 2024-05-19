module Battle
  module Effects
    class Item
      class TerrainSeeds < Item
        ITEM_DATA = {}
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || @logic.field_terrain == :none
          return unless @logic.field_terrain_effect.db_symbol == ITEM_DATA[@target.battle_item_db_symbol][:terrain]

          use_item_effect(handler)
        end

        # Function called after the field terrain was changed (on_post_fterrain_change)
        # @param handler [Battle::Logic::FTerrainChangeHandler]
        # @param fterrain_type [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @param last_fterrain [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def on_post_fterrain_change(handler, fterrain_type, last_fterrain)
          return if fterrain_type != ITEM_DATA[@target.battle_item_db_symbol][:terrain]

          use_item_effect(handler)
        end

        # Function processing the effect of the item
        # @param handler [Battle::Logic::FTerrainChangeHandler]
        def use_item_effect(handler)
          handler.scene.visual.show_item(@target)
          handler.logic.stat_change_handler.stat_change_with_process(ITEM_DATA[@target.battle_item_db_symbol][:stat], 1, @target)
          @target.item_holding = @target.battle_item = 0
        end

        private

        class << self
          # @param db_symbol [Symbol] db_symbol of the item
          # @param terrain [Symbol] symbol of the terrain triggering the item
          # @param stat [Float] symbol of the stat raised by the item
          # @param klass [Class<TerrainSeeds>] klass to instanciate
          def register(db_symbol, terrain, stat, klass = TerrainSeeds)
            Item.register(db_symbol, klass)
            ITEM_DATA[db_symbol] = { terrain: terrain, stat: stat }
          end
        end
        register(:grassy_seed, :grassy_terrain, :dfe)
        register(:electric_seed, :electric_terrain, :dfe)
        register(:psychic_seed, :psychic_terrain, :dfs)
        register(:misty_seed, :misty_terrain, :dfs)
      end
    end
  end
end
