module Battle
  module Effects
    class Weather
      class Hardrain < Weather
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 493)
        end

        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is evading the move
        def on_move_prevention_target(user, target, move)
          return false unless move.type_fire?

          move.scene.display_message_and_wait(parse_text_with_pokemon(18, 275, target))
          return true
        end

        # Function called when a weather_prevention is checked
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog, :hardsun, :hardrain
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog, :hardsun, :hardrain
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_weather_prevention(handler, weather_type, last_weather)
          return if %i[hardsun hardrain strong_winds].include?(weather_type)

          return handler.prevent_change do
            handler.scene.display_message_and_wait(parse_text(18, 277))
          end
        end

        # Give the move mod1 mutiplier (before the +2 in the formula)
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def mod1_multiplier(user, target, move)
          return move.type_water? ? 1.5 : 1
        end
      end
      register(:hardrain, Hardrain)
    end
  end
end