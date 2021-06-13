module Battle
  class Logic
    # Handler responsive of calling all the end turn events
    class EndTurnHandler
      include Hooks
      # List of abilities that blocks sandstorm damages
      SANDSTORM_BLOCKING_ABILITIES = %i[magic_guard sand_veil sand_rush sand_force overcoat]
      # List of abilities that blocks hail damages
      HAIL_BLOCKING_ABILITIES = %i[magic_guard ice_body snow_cloak overcoat]
      # Create a new end turn handler
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene]
      def initialize(logic, scene)
        @logic = logic
        @scene = scene
      end

      # Function that call all the events (end_turn_event)
      def process_events
        @alive_battlers = @logic.all_alive_battlers.dup
        exec_hooks(EndTurnHandler, :end_turn_event, binding)
        @logic.delete_dead_effects
      end

      class << self
        # Register a end turn event
        # @param reason [String] reason of the event
        # @yieldparam logic [Battle::Logic] logic of the battle
        # @yieldparam scene [Battle::Scene] battle scene
        # @yieldparam battlers [Array<PFM::PokemonBattler>] all alive battlers
        def register_end_turn_event(reason)
          Hooks.register(EndTurnHandler, :end_turn_event, reason) do
            @alive_battlers.reject!(&:dead?)
            yield(@logic, @scene, @alive_battlers)
          end
        end
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Effects') do |logic, scene, battlers|
      logic.each_effects(*battlers) do |e|
        e.on_end_turn_event(logic, scene, battlers)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Rain') do |logic, scene, battlers|
      next if $env.current_weather != 1

      if $env.decrease_weather_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 93))
        logic.weather_change_handler.weather_change(:none, 0)
      else
        scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 493)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Sunny') do |logic, scene, battlers|
      next if $env.current_weather != 2

      if $env.decrease_weather_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 92))
        logic.weather_change_handler.weather_change(:none, 0)
      else
        scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 492)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Sandstorm') do |logic, scene, battlers|
      next if $env.current_weather != 3

      if $env.decrease_weather_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 94))
        logic.weather_change_handler.weather_change(:none, 0)
      else
        scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 494)
        scene.display_message_and_wait(parse_text(18, 98))
        battlers.each do |battler|
          next if battler.type_rock? || battler.type_ground? || battler.type_steel?
          next if EndTurnHandler::SANDSTORM_BLOCKING_ABILITIES.include?(battler.battle_ability_db_symbol)

          logic.damage_handler.damage_change((battler.max_hp / 16).clamp(1, Float::INFINITY), battler)
        end
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Hail') do |logic, scene, battlers|
      next if $env.current_weather != 4

      if $env.decrease_weather_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 95))
        logic.weather_change_handler.weather_change(:none, 0)
      else
        scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 495)
        scene.display_message_and_wait(parse_text(18, 99))
        battlers.each do |battler|
          next if battler.type_ice?
          next if EndTurnHandler::HAIL_BLOCKING_ABILITIES.include?(battler.battle_ability_db_symbol)

          logic.damage_handler.damage_change((battler.max_hp / 16).clamp(1, Float::INFINITY), battler)
        end
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Fog') do |logic, scene, _|
      next if $env.current_weather != 5

      if $env.decrease_weather_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 96))
        logic.weather_change_handler.weather_change(:none, 0)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Nightmare') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.effects.has?(:nightmare) || battler.has_ability?(:magic_guard)
        next unless battler.asleep?

        hp = battler.max_hp / 4
        scene.display_message_and_wait(parse_text_with_pokemon(19, 324, battler))
        logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Curse') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.effects.has?(:curse) || battler.has_ability?(:magic_guard)

        hp = battler.max_hp / 4
        scene.display_message_and_wait(parse_text_with_pokemon(19, 1077, battler))
        logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
      end
    end

    # Electric Terrain
    EndTurnHandler.register_end_turn_event('PSDK end turn: Electric Terrain') do |logic, scene, _|
      next if $env.current_fterrain != 1

      if $env.decrease_fterrain_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 210))
        logic.fterrain_change_handler.fterrain_change(:terrainnone, 0)
      end
    end

    # Grassy Terrain
    EndTurnHandler.register_end_turn_event('PSDK end turn: Grassy Terrain') do |logic, scene, battlers|
      next if $env.current_fterrain != 2

      if $env.decrease_fterrain_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 206))
        logic.fterrain_change_handler.fterrain_change(:terrainnone, 0)
      else
        battlers.each do |battler|
          next unless battler.affected_by_terrain?
          next unless battler.hp < battler.max_hp

          scene.display_message_and_wait(parse_text_with_pokemon(19, 387, battler))
          scene.visual.show_hp_animations([battler], [battler.max_hp / 16])
        end
      end
    end

    # Misty Terrain
    EndTurnHandler.register_end_turn_event('PSDK end turn: Misty Terrain') do |logic, scene, _|
      next if $env.current_fterrain != 3

      if $env.decrease_fterrain_duration # Return true if stopping!
        scene.display_message_and_wait(parse_text(18, 208))
        logic.fterrain_change_handler.fterrain_change(:terrainnone, 0)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Psychic Terrain') do |logic, _, _|
      next if $env.current_fterrain != 4

      if $env.decrease_fterrain_duration # Return true if stopping!
        # TODO: Add gen7 text of Psychic Terrain
        logic.fterrain_change_handler.fterrain_change(:terrainnone, 0)
      end
    end
  end
end
