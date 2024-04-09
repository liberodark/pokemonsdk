# Weather introduced in Gen IX
# Similar to sandstorm, but gives ice types a defense stat boost
# Snow does not damage non-ice types
module Battle
  module Effects
    class Weather
      class Snow < Weather
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          if $env.decrease_weather_duration
            scene.display_message_and_wait(parse_text(18, 288))
            logic.weather_change_handler.weather_change(:none, 0)
          else
            scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 495)
            scene.display_message_and_wait(parse_text(18, 289))
          end
        end

        # Give the move [Spe]def mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_def_multiplier(user, target, move)
          return 1 if move.special?
          return 1 unless target.type_ice?

          return move.physical? ? 1.5 : 1
        end
      end
      register(:snow, Snow)
    end
  end
end
