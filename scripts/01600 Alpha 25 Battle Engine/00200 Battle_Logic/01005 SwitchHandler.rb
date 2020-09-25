module Battle
  class Logic
    # Handler responsive of processing switch events that happens during switch
    class SwitchHandler < ChangeHandlerBase
      include Hooks

      # Test if the switch is possible
      # @param pokemon [PFM::PokemonBattler] pokemon to switch
      # @param skill [Battle::Move, nil] potential move
      # @return [Boolean] if it can switch or not
      def can_switch?(pokemon, skill = nil)
        return false if pokemon.hp <= 0

        reset_prevention_reason
        exec_hooks(SwitchHandler, :switch_passthrough, binding)
        exec_hooks(SwitchHandler, :switch_prevention, binding)
        return true
      rescue Hooks::ForceReturn => e
        return e.data
      end

      # Perform the switch between two Pokemon
      # @param who [PFM::PokemonBattler] Pokemon who is switched out
      # @param with [PFM::PokemonBattler, nil] Pokemon who is switched in
      # @note In the event we're starting the battle who & with should be identic, this help to process effect like Intimidate
      def execute_switch_events(who, with)
        if with != who
          with.battle_effect = Pokemon_Effect.new
          with.turn_count = 0
        end
        exec_hooks(SwitchHandler, :switch_event, binding)
      end

      class << self
        # Register a switch passthrough. If the block returns :passthrough, it will say that Pokemon can switch in can_switch?
        # @param reason [String] reason of the switch_passthrough hook
        # @yieldparam handler [SwitchHandler]
        # @yieldparam pokemon [PFM::PokemonBattler]
        # @yieldparam skill [Battle::Move, nil] potential skill used to switch
        # @yieldreturn [:passthrough, nil] if :passthrough, can_switch? will return true without checking switch_prevention
        def register_switch_passthrough_hook(reason)
          Hooks.register(SwitchHandler, :switch_passthrough, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:pokemon),
              hook_binding.local_variable_get(:skill)
            )
            force_return(true) if result == :passthrough
          end
        end

        # Register a switch prevention hook. If the block returns :prevent, it will say that Pokemon cannot switch in can_switch?
        # @param reason [String] reason of the switch_prevention hook
        # @yieldparam handler [SwitchHandler]
        # @yieldparam pokemon [PFM::PokemonBattler]
        # @yieldparam skill [Battle::Move, nil] potential skill used to switch
        # @yieldreturn [:prevent, nil] if :prevent, can_switch? will return false
        def register_switch_prevention_hook(reason)
          Hooks.register(SwitchHandler, :switch_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:pokemon),
              hook_binding.local_variable_get(:skill)
            )
            force_return(false) if result == :prevent
          end
        end

        # Register a switch event
        # @param reason [String] reason of the switch_event hook
        # @yieldparam handler [SwitchHandler]
        # @yieldparam who [PFM::PokemonBattler] Pokemon that is switched out
        # @yieldparam with [PFM::PokemonBattler] Pokemon that is switched in
        def register_switch_event_hook(reason)
          Hooks.register(SwitchHandler, :switch_event, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:who),
              hook_binding.local_variable_get(:with)
            )
          end
        end
      end
    end

    # Shed Shell
    SwitchHandler.register_switch_passthrough_hook('PSDK switch pass: Shed Shell') do |_, pokemon|
      next :passthrough if pokemon.item_db_symbol == :shed_shell
    end

    # Shadow Tag
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Shadow Tag') do |handler, pokemon|
      next if pokemon.ability_db_symbol == :shadow_tag
      next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe.ability_db_symbol == :shadow_tag })

      next handler.prevent_change do
        handler.scene.visual.show_ability(fv)
      end
    end

    # Magnet Pull
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Magnet Pull') do |handler, pokemon|
      next unless pokemon.type_steel?
      next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe.ability_db_symbol == :magnet_pull })

      next handler.prevent_change do
        handler.scene.visual.show_ability(fv)
      end
    end

    # Bind
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Bind') do |_, pokemon|
      next unless pokemon.battle_effect.has_bind_effect?

      next :prevent
    end

    # Ingrain
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Ingrain') do |_, pokemon|
      next if pokemon.type_ghost? || !pokemon.battle_effect.has_ingrain_effect?

      next :prevent
    end

    # Arena Trap
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Arena Trap') do |handler, pokemon|
      next unless false # pokemon.grounded? TODO: Create the grounded property on POKEMON
      next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe.ability_db_symbol == :arena_trap })

      next handler.prevent_change do
        handler.scene.visual.show_ability(fv)
      end
    end

    # Can't flee effect
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Cant flee') do |handler, pokemon|
      next unless pokemon.battle_effect.has_cant_attack_effect?
      next unless handler.logic.all_alive_battlers.include?(pokemon.battle_effect.get_cant_flee_launcher)

      next :prevent
    end

    # Natural Cure
    SwitchHandler.register_switch_event_hook('PSDK switch: Natural Cure') do |handler, who, with|
      next if who == with || who.ability_db_symbol != :natural_cure || who.status == 0

      handler.scene.visual.show_ability(who)
      handler.logic.status_change_handler.status_change_with_process(:cure, who)
    end

    # Lunar Dance
    SwitchHandler.register_switch_event_hook('PSDK switch: Lunar Dance') do |handler, who, with|
      next if who.last_successfull_move != :lunar_dance || who.last_battle_turn != $game_temp.battle_turn

      handler.scene.display_message(parse_text_with_pokemon(19, 694, with))
      handler.scene.visual.show_hp_animations([with], [with.max_hp])
      handler.logic.status_change_handler.status_change_with_process(:cure, with)
    end

    # Healing Wish
    SwitchHandler.register_switch_event_hook('PSDK switch: Healing Wish') do |handler, who, with|
      next if who.last_successfull_move != :healing_wish || who.last_battle_turn != $game_temp.battle_turn

      handler.scene.display_message(parse_text_with_pokemon(19, 697, with))
      handler.scene.visual.show_hp_animations([with], [with.max_hp])
      handler.logic.status_change_handler.status_change_with_process(:cure, with)
    end

    # Wish
    SwitchHandler.register_switch_event_hook('PSDK switch: Wish') do |_, who, with|
      next if who == with || !who.battle_effect.has_wish_effect?

      with.battle_effect.apply_wish(who.battle_effect.get_wisher, 1)
    end

    # Mimic
    SwitchHandler.register_switch_event_hook('PSDK switch: mimic') do |_, who|
      who.moveset.each(&:reset)
    end

    # Baton Pass
    SwitchHandler.register_switch_event_hook('PSDK switch: Baton Pass') do |handler, who, with|
      next if who.last_successfull_move != :baton_pass || who.last_battle_turn != $game_temp.battle_turn

      with.battle_effect.transmit_bind(who.battle_effect) if who.battle_effect.has_bind_effect?
      handler.logic.status_change_handler(:confuse, with) if who.confused?
      with.battle_effect.apply_aqua_ring if who.battle_effect.has_aqua_ring_effect?
      with.battle_effect.transmit_substitute(who.battle_effect) if who.battle_effect.has_substitute_effect?
    end

    # Intimidate
    SwitchHandler.register_switch_event_hook('PSDK switch: Intimidate') do |handler, who, with|
      # If with is entering the battle => all foes get the malus
      if with.ability_db_symbol == :intimidate
        alive_foes = handler.logic.foes_of(with).select(&:alive?)
        handler.scene.visual.show_ability(with) if alive_foes.any?
        alive_foes.each do |foe|
          handler.logic.stat_change_handler.stat_change_with_process(:atk, -1, foe)
        end
      end
    end

    # Trace
    SwitchHandler.register_switch_event_hook('PSDK switch: Trace') do |handler, _, with|
      next if with.ability_db_symbol != :trace

      foes = handler.logic.foes_of(with).select { |foe| foe.alive? && foe.ability_db_symbol != :__undef__ }
      next if foes.none?

      handler.scene.visual.show_ability(with)
      with.ability_current = foes.sample.ability_current
      handler.scene.display_message(parse_text_with_pokemon(19, 381, with, PFM::Text::ABILITY[1] => with.ability_name))
    end

    # Pressure
    SwitchHandler.register_switch_event_hook('PSDK switch: Pressure') do |handler, _, with|
      next if with.ability_db_symbol != :pressure

      handler.scene.visual.show_ability(with)
      handler.scene.display_message(parse_text_with_pokemon(19, 487, with))
    end

    # Drizzle
    SwitchHandler.register_switch_event_hook('PSDK switch: Drizzle') do |handler, _, with|
      next if with.ability_db_symbol != :drizzle

      # TODO: WeatherHandler
      # next unless handler.logic.weather_handler.can_change_weather?
      nb_turn = with.item_db_symbol == :damp_rock ? 8 : 5
      # handler.logic.weather_handler.change_weather(:rain, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 493)
    end

    # Drought
    SwitchHandler.register_switch_event_hook('PSDK switch: Drought') do |handler, _, with|
      next if with.ability_db_symbol != :drought

      # TODO: WeatherHandler
      # next unless handler.logic.weather_handler.can_change_weather?
      nb_turn = with.item_db_symbol == :damp_rock ? 8 : 5
      # handler.logic.weather_handler.change_weather(:sunny, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 492)
    end

    # Sand Stream
    SwitchHandler.register_switch_event_hook('PSDK switch: Sand Stream') do |handler, _, with|
      next if with.ability_db_symbol != :sand_stream

      # TODO: WeatherHandler
      # next unless handler.logic.weather_handler.can_change_weather?
      nb_turn = with.item_db_symbol == :damp_rock ? 8 : 5
      # handler.logic.weather_handler.change_weather(:sandstorm, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 494)
    end

    # Snow Warning
    SwitchHandler.register_switch_event_hook('PSDK switch: Snow Warning') do |handler, _, with|
      next if with.ability_db_symbol != :snow_warning

      # TODO: WeatherHandler
      # next unless handler.logic.weather_handler.can_change_weather?
      nb_turn = with.item_db_symbol == :damp_rock ? 8 : 5
      # handler.logic.weather_handler.change_weather(:hail, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 494)
    end

    # Anticipation
    SwitchHandler.register_switch_event_hook('PSDK switch: Anticipation') do |handler, _, with|
      next if with.ability_db_symbol != :anticipation

      handler.logic.foes_of(with).each do |foe|
        next false if foe.dead?
        next false if foe.moveset.none? { |move| move.type_modifier(with) >= 2 }

        handler.scene.visual.show_ability(with)
        handler.scene.display_message(parse_text_with_pokemon(19, 436, with))
      end
    end

    # Forewarn
    SwitchHandler.register_switch_event_hook('PSDK switch: Forewarn') do |handler, _, with|
      next if with.ability_db_symbol != :forewarn

      alive_foes = handler.logic.foes_of(with).select(&:alive?)
      next if alive_foes.empty?

      dangers = alive_foes.map do |foe|
        next [
          foe,
          foe.moveset.shuffle.max_by(&:power)
        ]
      end
      danger_foe, danger_move = dangers.shuffle.max_by { |(_, move)| move.power }
      next if danger_move.power <= 0

      handler.scene.visual.show_ability(with)
      handler.scene.display_message(parse_text_with_pokemon(19, 433, danger_foe, PFM::Text::MOVE[1] => danger_move.name))
    end

    # Frisk
    SwitchHandler.register_switch_event_hook('PSDK switch: Forewarn') do |handler, _, with|
      next if with.ability_db_symbol != :frisk

      foe_item = handler.logic.foes_of(with).find { |foe| foe.alive? && foe.item_db_symbol != :__undef__ }
      next unless foe_item

      handler.scene.visual.show_ability(with)
      handler.scene.display_message(parse_text_with_pokemon(19, 439, with, PFM::Text::PKNICK[1] => foe_item.given_name,
                                                                           PFM::Text::ITEM2[2] => foe_item.item_name))
    end

    # Download
    SwitchHandler.register_switch_event_hook('PSDK Switch: Download') do |handler, _, with|
      next if with.ability_db_symbol != :download

      random_foe = handler.logic.foes_of(with).shuffle.find(&:alive?)
      next unless random_foe

      handler.scene.visual.show_ability(with)
      handler.logic.stat_change_handler.stat_change_with_process(random_foe.dfe < random_foe.dfs ? :atk : :ats, 1, with)
    end
  end
end
