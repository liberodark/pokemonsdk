module Battle
  module Effects
    class Ability
      class QuarkDrive < Ability
        # @return [Hash{ Symbol => Integer }] A hash mapping stats to their corresponding text IDs.
        TEXTS_IDS = {
          atk: 1702,
          dfe: 1706,
          ats: 1710,
          dfs: 1714,
          spd: 1718
        }

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
          return play_ability_effect(handler, @target, :item) if @target.hold_item?(:booster_energy)
        end

        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 1.3 if @highest_stat == :atk

          return super
        end

        # Give the dfe modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfe_modifier
          return 1.3 if @highest_stat == :dfe

          return super
        end

        # Give the speed modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def spd_modifier
          return 1.5 if @highest_stat == :spd

          return super
        end

        # Give the ats modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def ats_modifier
          return 1.3 if @highest_stat == :ats

          return super
        end

        # Give the dfs modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfs_modifier
          return 1.3 if @highest_stat == :dfs

          return super
        end

        private

        # Plays pokemon ability effect
        # @param handler [Battle::Logic::SwitchHandler]
        # @param pokemon [PFM::PokemonBattler]
        # @param reason [Symbol] the reason of the proc
        def play_ability_effect(handler, pokemon, reason)
          result = highest_stat_boosted
          return if result == @highest_stat

          case reason
          when :env
            handler.scene.visual.show_ability(pokemon)
            handler.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text_with_pokemon(66, 1642, pokemon))
          when :item
            handler.scene.visual.show_item(pokemon)
            handler.scene.visual.wait_for_animation
            handler.logic.item_change_handler.change_item(:none, true, pokemon)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(66, 1638, pokemon))
          end

          @highest_stat = result
          handler.scene.display_message_and_wait(parse_text_with_pokemon(66, TEXTS_IDS[@highest_stat], pokemon))
        end

        # Function called to increase the pokemon's highest stat
        # @return [Symbol] the highest stat
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
