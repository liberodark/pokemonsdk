module Battle
  module Effects
    class Ability
      class Protosynthesis < Ability
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

          return play_ability_effect(handler, with, :env) if %i[sunny hardsun].include?($env.current_weather_db_symbol)

          return play_ability_effect(handler, with, :item) if with.hold_item?(:booster_energy)
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          @highest_stat = nil if %i[sunny hardsun].include?(last_weather)

          return play_ability_effect(handler, @target, :env) if %i[sunny hardsun].include?(weather_type)

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

        # Function called to increase the pokémon's highest stat
        def highest_stat_boosted
          stats = { atk: @target.atk, dfe: @target.dfe, ats: @target.ats, dfs: @target.dfs, spd: @target.spd }

          highest_value = stats.values.max
          highest_stat_key = stats.key(highest_value)
          return highest_stat_key.to_sym
        end
      end
      register(:protosynthesis, Protosynthesis)
    end
  end
end