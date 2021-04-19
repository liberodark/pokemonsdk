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
        @alive_battlers.each do |battler|
          battler.battle_effect.update_counter(battler)
        end
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

    EndTurnHandler.register_end_turn_event('PSDK end turn: Perish Song') do |logic, scene, battlers|
      battlers.each do |battler|
        next unless battler.battle_effect.has_perish_song_effect?

        battler.battle_effect.dec_perish_song_counter
        counter = battler.battle_effect.get_perish_song_counter
        scene.display_message_and_wait(parse_text_with_pokemon(19, 863, battler, PFM::Text::NUMB[2] => counter.to_s))
        logic.damage_handler.damage_change(-battler.hp, battler) if counter == 0 # We purposedly ignore stuff that could prevent HP from going down
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

    EndTurnHandler.register_end_turn_event('PSDK end turn: Forecast') do |_, scene, battlers|
      battlers.each do |battler|
        next unless battler.has_ability?(:forecast)

        original_form = battler.form
        battler.form_calibrate
        scene.visual.show_switch_form_animation(battler) if battler.form != original_form
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Yawn') do |logic, _, battlers|
      battlers.each do |battler|
        next if battler.has_ability?(:magic_guard)
        next unless battler.battle_effect.fell_asleep_from_yawning?

        logic.status_change_handler.status_change(:sleep, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Wish') do |_, scene, battlers|
      battlers.each do |battler|
        next unless battler.battle_effect.has_wish_effect?

        scene.display_message_and_wait(parse_text_with_pokemon(19, 700, battler.battle_effect.get_wisher))
        scene.visual.show_hp_animations([battler], [(battler.max_hp / 2).clamp(1, Float::INFINITY)])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Ingrain') do |_, scene, battlers|
      battlers.each do |battler|
        next unless battler.battle_effect.has_ingrain_effect?

        scene.display_message_and_wait(parse_text_with_pokemon(19, 739, battler))
        scene.visual.show_hp_animations([battler], [(battler.max_hp / 16).clamp(1, Float::INFINITY)])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Aqua Ring') do |_, scene, battlers|
      battlers.each do |battler|
        next unless battler.battle_effect.has_aqua_ring_effect?

        scene.display_message_and_wait(parse_text_with_pokemon(19, 604, battler))
        scene.visual.show_hp_animations([battler], [(battler.max_hp / 16).clamp(1, Float::INFINITY)])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Rain Dish') do |_, scene, battlers|
      battlers.each do |battler|
        next unless $env.rain? && battler.has_ability?(:rain_dish)

        scene.visual.show_ability(battler)
        scene.visual.show_hp_animations([battler], [battler.max_hp / 16])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Shed Skin') do |logic, scene, battlers|
      battlers.each do |battler|
        next if battler.status == 0 || bchance?(0.66) || !battler.has_ability?(:shed_skin)

        scene.visual.show_ability(battler)
        logic.status_change_handler.status_change(:cure, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Hydration') do |logic, scene, battlers|
      battlers.each do |battler|
        next if battler.status == 0
        next unless $env.rain? && battler.has_ability?(:hydration)

        scene.visual.show_ability(battler)
        logic.status_change_handler.status_change(:cure, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Ice Body') do |_, scene, battlers|
      battlers.each do |battler|
        next unless $env.hail? && battler.has_ability?(:ice_body)

        scene.visual.show_ability(battler)
        scene.visual.show_hp_animations([battler], [(battler.max_hp / 16).clamp(1, Float::INFINITY)])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Dry Skin') do |_, scene, battlers|
      battlers.each do |battler|
        next unless $env.rain? && battler.has_ability?(:dry_skin)

        scene.visual.show_ability(battler)
        scene.visual.show_hp_animations([battler], [(battler.max_hp / 16).clamp(1, Float::INFINITY)])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Black Sludge') do |logic, scene, battlers|
      battlers.each do |battler|
        next unless battler.hold_item?(:black_sludge)

        if battler.type_poison?
          scene.visual.show_item(battler)
          scene.visual.show_hp_animations([battler], [(battler.max_hp / 16).clamp(1, Float::INFINITY)])
        elsif !battler.has_ability?(:magic_guard)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1048, battler, PFM::Text::ITEM2[1] => battler.item_name))
          logic.damage_handler.damage_change(-(battler.max_hp / 8).clamp(1, Float::INFINITY), battler)
        end
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Flame Orb') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.hold_item?(:flame_orb) || battler.turn_count > 0 || battler.has_ability?(:magic_guard)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 1048, battler, PFM::Text::ITEM2[1] => battler.item_name))
        logic.status_change_handler.status_change(:burn, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Toxic Orb') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.hold_item?(:toxic_orb) || battler.turn_count > 0 || battler.has_ability?(:magic_guard)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 1048, battler, PFM::Text::ITEM2[1] => battler.item_name))
        logic.status_change_handler.status_change(:toxic, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Life Orb') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.hold_item?(:life_orb) || battler.attack_order.is_a?(Integer) || battler.has_ability?(:magic_guard)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 1048, battler, PFM::Text::ITEM2[1] => battler.item_name))
        logic.damage_handler.damage_change(-(battler.max_hp / 8).clamp(1, Float::INFINITY), battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Sticky Barb') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.hold_item?(:sticky_barb) || battler.has_ability?(:magic_guard)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 1048, battler, PFM::Text::ITEM2[1] => battler.item_name))
        logic.damage_handler.damage_change(-(battler.max_hp / 8).clamp(1, Float::INFINITY), battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Leftovers') do |_, scene, battlers|
      battlers.each do |battler|
        next unless battler.hold_item?(:leftovers)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 918, battler, PFM::Text::ITEM2[1] => battler.item_name))
        scene.visual.show_hp_animations([battler], [(battler.max_hp / 8).clamp(1, Float::INFINITY)])
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Poison') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.poisoned? || battler.has_ability?(:magic_guard)

        if battler.has_ability?(:poison_heal)
          if battler.effects.has?(:heal_block)
            scene.display_message_and_wait(parse_text_with_pokemon(19, 890, battler))
            next
          end
          scene.display_message_and_wait(parse_text_with_pokemon(19, 387, battler))
          scene.visual.show_hp_animations([battler], [battler.poison_effect])
          next
        end

        scene.display_message_and_wait(parse_text_with_pokemon(19, 243, battler))
        scene.visual.show_rmxp_animation(battler, 469 + battler.status)
        logic.damage_handler.damage_change(battler.poison_effect, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Toxic') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.toxic? || battler.has_ability?(:magic_guard)

        scene.display_message_and_wait(parse_text_with_pokemon(19, 243, battler))
        scene.visual.show_rmxp_animation(battler, 469 + battler.status)
        logic.damage_handler.damage_change(battler.toxic_effect, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Burn') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.burn? || battler.has_ability?(:magic_guard)

        hp = battler.burn_effect
        hp /= 2 if battler.has_ability?(:heatproof)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 261, battler))
        scene.visual.show_rmxp_animation(battler, 469 + battler.status)
        logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Bind') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.battle_effect.has_bind_effect? || battler.has_ability?(:magic_guard)

        hp = battler.battle_effect.get_bide_power(battler)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 1086, battler, PFM::Text::MOVE[1] => battler.battle_effect.get_bind_skill_name))
        logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Nightmare') do |logic, scene, battlers|
      battlers.each do |battler|
        next if !battler.battle_effect.has_nightmare_effect? || battler.has_ability?(:magic_guard)

        if battler.asleep?
          hp = battler.max_hp / 4
          scene.display_message_and_wait(parse_text_with_pokemon(19, 324, battler))
          logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
        else
          battler.battle_effect.apply_nightmare(false)
        end
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

    EndTurnHandler.register_end_turn_event('PSDK end turn: Speed Boost') do |logic, scene, battlers|
      battlers.each do |battler|
        next unless battler.has_ability?(:speed_boost) && battler.spd_stage < PFM::PokemonBattler::MAX_STAGE

        scene.visual.show_ability(battler)
        logic.stat_change_handler.stat_change_with_process(:spd, 1, battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Moody') do |logic, scene, battlers|
      battlers.each do |battler|
        next unless battler.has_ability?(:moody)

        stats = Battle::Logic::StatChangeHandler::ALL_STATS
        stat_up = stats.reject do |stat|
          battler.battle_stage[Battle::Logic::StatChangeHandler::STAT_INDEX[stat]] == PFM::PokemonBattler::MAX_STAGE
        end.sample
        stat_down = stats.reject do |stat|
          battler.battle_stage[Battle::Logic::StatChangeHandler::STAT_INDEX[stat]] == PFM::PokemonBattler::MIN_STAGE || stat == stat_up
        end.sample
        next unless stat_down || stat_up

        scene.visual.show_ability(battler)
        logic.stat_change_handler.stat_change_with_process(stat_up, 2, battler) if stat_up
        logic.stat_change_handler.stat_change_with_process(stat_down, -1, battler) if stat_down
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Dry Skin (damage)') do |logic, scene, battlers|
      battlers.each do |battler|
        next unless $env.sunny? && battler.has_ability?(:dry_skin)

        hp = battler.max_hp / 8
        scene.visual.show_ability(battler)
        logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
      end
    end

    EndTurnHandler.register_end_turn_event('PSDK end turn: Bad Dreams') do |logic, scene, battlers|
      battlers.each do |battler|
        next unless battler.has_ability?(:bad_dreams)

        sleeping_foes = logic.foes_of(battler).select(&:asleep?)
        scene.visual.show_ability(battler) if sleeping_foes.any?
        sleeping_foes.each do |sleeping_foe|
          hp = sleeping_foe.max_hp / 8
          logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), battler)
        end
      end
    end

    # Zen Mode
    EndTurnHandler.register_end_turn_event('PSDK end turn: Zen Mode') do |_, scene, battlers|
      battlers.each do |battler|
        next unless battler.has_ability?(:zen_mode)

        original_form = battler.form
        battler.form_calibrate(:battle)
        next if battler.form == original_form

        scene.visual.show_ability(battler)
        scene.visual.show_switch_form_animation(battler)
        scene.display_message_and_wait(parse_text(18, battler.form.odd? ? 191 : 192))
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
