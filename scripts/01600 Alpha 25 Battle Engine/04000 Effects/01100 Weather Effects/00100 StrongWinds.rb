module Battle
  module Effects
    class Weather
      class StrongWinds < Weather
        # Create a new effect
        # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
        def initialize(logic, db_symbol)
          @super_effective_types = each_data_type.select { |type| type.hit(:flying) > 1 }.map(&:id)
          super(logic, db_symbol)
        end

        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          # TODO: replace by on_ability_change (hook doesn't exist yet)
          if battlers.none? { |battler| battler.has_ability?(:delta_stream) }
            logic.weather_change_handler.weather_change(:none, 0)
            return scene.display_message_and_wait(parse_text(18, 274))
          end

          scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 566)
        end

        # Function called when a weather_prevention is checked
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog, :hardsun, :hardrain
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog, :hardsun, :hardrain
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_weather_prevention(handler, weather_type, last_weather)
          return if %i[hardsun hardrain strong_winds].include?(weather_type)

          return handler.prevent_change do
            handler.scene.display_message_and_wait(parse_text(18, 280))
          end
        end

        # Function called before the accuracy check of a move is done
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param targets [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_accuracy_check(logic, scene, targets, launcher, skill)
          return if skill.status?
          return if targets.none?(&:type_flying?)
          if targets.none? { |target| @super_effective_types.any? { |super_effective_type| skill.definitive_types(launcher, target).include?(super_effective_type) } }
            return false
          end

          skill.scene.display_message_and_wait(parse_text(18, 279))
        end

        # Function that computes an overwrite of the type multiplier
        # @param target [PFM::PokemonBattler]
        # @param target_type [Integer] one of the type of the target
        # @param type [Integer] one of the type of the move
        # @param move [Battle::Move]
        # @return [Float, nil] overwriten type multiplier
        def on_single_type_multiplier_overwrite(target, target_type, type, move)
          return unless target_type == data_type(:flying).id

          return 1 if @super_effective_types.any? { |super_effective_type| super_effective_type == type }
        end
      end
      register(:strong_winds, StrongWinds)
    end
  end
end
