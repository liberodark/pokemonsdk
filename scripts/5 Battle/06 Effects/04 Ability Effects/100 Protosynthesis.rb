module Battle
  module Effects
    class Ability
      class Protosynthesis < Ability
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

        # Give the move [Spe]atk mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_atk_multiplier(user, target, move)
          return 1 unless @highest_stat
          return 1 if user != @target

          return case @highest_stat
                 when :atk
                   move.physical? ? 1.3 : 1
                 when :ats
                   move.special? ? 1.3 : 1
                 else
                   1
                 end
        end

        # Give the move [Spe]def mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_def_multiplier(user, target, move)
          return 1 unless @highest_stat
          return 1 if target != @target

          return case @highest_stat
                 when :dfe
                   move.physical? ? 1.3 : 1
                 when :dfs
                   move.special? ? 1.3 : 1
                 else
                   1
                 end
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
          handler.scene.display_message_and_wait(parse_text_with_pokemon(66, 1626, pokemon))
          handler.scene.display_message_and_wait(parse_text_with_pokemon(66, TEXTS_IDS[@highest_stat], pokemon))
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
