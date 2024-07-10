module Battle
  module Effects
    class Ability
      class QuarkDrive < Ability
        # Create a new FlowerGift effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @highest_stat = nil
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target

          return play_ability_effect(handler, with, :env) if handler.logic.field_terrain_effect.electric?

          return play_ability_effect(handler, with, :item) if with.hold_item?(:booster_energy)
        end

        # Function called after the terrain was changed
        # @param handler [Battle::Logic::FTerrainChangeHandler]
        # @param fterrain_type [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @param last_fterrain [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def on_post_fterrain_change(handler, fterrain_type, last_fterrain)
          @highest_stat = nil if last_fterrain == :electric_terrain

          return play_ability_effect(handler, @target, :env) if fterrain_type == :electric_terrain

          play_ability_effect(handler, with, :item) if @target.hold_item?(:booster_energy)
        end

        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return super unless @highest_stat == :atk

          return 1.3
        end

        # Give the dfe modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfe_modifier
          return super unless @highest_stat == :dfe

          return 1.3
        end

        # Give the ats modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def ats_modifier
          return super unless @highest_stat == :ats

          return 1.3
        end

        # Give the dfs modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfs_modifier
          return super unless @highest_stat == :dfs

          return 1.3
        end

        # Give the speed modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def spd_modifier
          return super unless @highest_stat == :spd

          return 1.5
        end

        private

        # Plays pokemon ability effect
        # @param handler [Battle::Logic::SwitchHandler]
        # @param pokemon [PFM::PokemonBattler]
        # @param reason [Symbol] the reason of the proc
        def play_ability_effect(handler, pokemon, reason)
          case reason
          when :env 
            handler.scene.visual.show_ability(pokemon)
            handler.scene.visual.wait_for_animation
          when :item
            handler.scene.visual.show_item(pokemon)
            handler.scene.visual.wait_for_animation
            handler.logic.item_change_handler.change_item(:none, true, pokemon)
          end

          @highest_stat = highest_stat_boosted
          #TODO: Add the corresponding text
        end

        # Function called to increase the pokemon's highest stat
        def highest_stat_boosted
          stats = { atk: @target.atk, dfe: @target.dfe, ats: @target.ats, dfs: @target.dfs, spd: @target.spd }

          highest_value = stats.values.max
          highest_stat_key = stats.key(highest_value)
          return highest_stat_key.to_sym
        end
      end
      register(:quark_drive, QuarkDrive)
    end
  end
end