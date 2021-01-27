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

    # Effects
    SwitchHandler.register_switch_passthrough_hook('PSDK switch pass: Effects') do |handler, pokemon, skill|
      next handler.logic.each_effects(pokemon) do |e|
        next e.on_switch_passthrough(handler, pokemon, skill)
      end
    end
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Effects') do |handler, pokemon, skill|
      next handler.logic.each_effects(pokemon) do |e|
        next e.on_switch_prevention(handler, pokemon, skill)
      end
    end
    SwitchHandler.register_switch_event_hook('PSDK switch: Effects') do |handler, who, with|
      next handler.logic.each_effects(who, with) do |e|
        next e.on_switch_event(handler, who, with)
      end
    end

    # Shed Shell
    SwitchHandler.register_switch_passthrough_hook('PSDK switch pass: Shed Shell') do |_, pokemon|
      next :passthrough if pokemon.hold_item?(:shed_shell)
    end

    # Shadow Tag
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Shadow Tag') do |handler, pokemon|
      next if pokemon.has_ability?(:shadow_tag)
      next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe&.has_ability?(:shadow_tag) })

      next handler.prevent_change do
        handler.scene.visual.show_ability(fv)
      end
    end

    # Magnet Pull
    SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Magnet Pull') do |handler, pokemon|
      next unless pokemon.type_steel?
      next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe&.has_ability?(:magnet_pull) })

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
      next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe&.has_ability?(:arena_trap) })

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
      next if who == with || !who.has_ability?(:natural_cure) || who.status == 0

      handler.scene.visual.show_ability(who)
      handler.logic.status_change_handler.status_change_with_process(:cure, who)
    end

    # Lunar Dance
    SwitchHandler.register_switch_event_hook('PSDK switch: Lunar Dance') do |handler, who, with|
      last_move = who.move_history.last
      next if !last_move || last_move.db_symbol != :lunar_dance || !last_move.current_turn?

      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 694, with))
      handler.scene.visual.show_hp_animations([with], [with.max_hp])
      handler.logic.status_change_handler.status_change_with_process(:cure, with)
    end

    # Healing Wish
    SwitchHandler.register_switch_event_hook('PSDK switch: Healing Wish') do |handler, who, with|
      last_move = who.move_history.last
      next if !last_move || last_move.db_symbol != :healing_wish || !last_move.current_turn?

      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 697, with))
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
      last_move = who.move_history.last
      next if !last_move || last_move.db_symbol != :baton_pass || !last_move.current_turn?

      with.battle_effect.transmit_bind(who.battle_effect) if who.battle_effect.has_bind_effect?
      handler.logic.status_change_handler(:confuse, with) if who.confused?
      with.battle_effect.apply_aqua_ring if who.battle_effect.has_aqua_ring_effect?
      with.battle_effect.transmit_substitute(who.battle_effect) if who.battle_effect.has_substitute_effect?
    end

    # Intimidate
    SwitchHandler.register_switch_event_hook('PSDK switch: Intimidate') do |handler, _, with|
      # If with is entering the battle => all foes get the malus
      if with.has_ability?(:intimidate)
        alive_foes = handler.logic.foes_of(with).select(&:alive?)
        handler.scene.visual.show_ability(with) if alive_foes.any?
        alive_foes.each do |foe|
          handler.logic.stat_change_handler.stat_change_with_process(:atk, -1, foe)
        end
      end
    end

    # Trace
    SwitchHandler.register_switch_event_hook('PSDK switch: Trace') do |handler, _, with|
      next unless with.has_ability?(:trace)

      foes = handler.logic.foes_of(with).select do |foe|
        next foe.alive? && foe.ability_db_symbol != :__undef__ &&
          handler.logic.ability_change_handler.can_change_ability?(with, foe.ability_db_symbol) # Checking if with can change to foe ability
      end
      next if foes.none?

      handler.scene.visual.show_ability(with)
      handler.logic.ability_change_handler.change_ability(with, foes.sample.ability_db_symbol)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 381, with, PFM::Text::ABILITY[1] => with.ability_name))
    end

    # Pressure
    SwitchHandler.register_switch_event_hook('PSDK switch: Pressure') do |handler, _, with|
      next unless with.has_ability?(:pressure)

      handler.scene.visual.show_ability(with)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 487, with))
    end

    # Drizzle
    SwitchHandler.register_switch_event_hook('PSDK switch: Drizzle') do |handler, _, with|
      next unless with.has_ability?(:drizzle)

      weather_handler = handler.logic.weather_change_handler
      next unless weather_handler.weather_appliable?(:rain)

      nb_turn = with.hold_item?(:damp_rock) ? 8 : 5
      weather_handler.weather_change(:rain, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 493)
    end

    # Drought
    SwitchHandler.register_switch_event_hook('PSDK switch: Drought') do |handler, _, with|
      next unless with.has_ability?(:drought)

      weather_handler = handler.logic.weather_change_handler
      next unless weather_handler.weather_appliable?(:sunny)

      nb_turn = with.hold_item?(:damp_rock) ? 8 : 5
      weather_handler.weather_change(:sunny, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 492)
    end

    # Sand Stream
    SwitchHandler.register_switch_event_hook('PSDK switch: Sand Stream') do |handler, _, with|
      next unless with.has_ability?(:sand_stream)

      weather_handler = handler.logic.weather_change_handler
      next unless weather_handler.weather_appliable?(:sandstorm)

      nb_turn = with.hold_item?(:damp_rock) ? 8 : 5
      weather_handler.weather_change(:sandstorm, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 494)
    end

    # Snow Warning
    SwitchHandler.register_switch_event_hook('PSDK switch: Snow Warning') do |handler, _, with|
      next unless with.has_ability?(:snow_warning)

      weather_handler = handler.logic.weather_change_handler
      next unless weather_handler.weather_appliable?(:hail)

      nb_turn = with.hold_item?(:damp_rock) ? 8 : 5
      weather_handler.weather_change(:hail, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.visual.show_rmxp_animation(with, 494)
    end

    # Anticipation
    SwitchHandler.register_switch_event_hook('PSDK switch: Anticipation') do |handler, _, with|
      next unless with.has_ability?(:anticipation)

      handler.logic.foes_of(with).each do |foe|
        next false if foe.dead?
        next false if foe.moveset.none? { |move| move.type_modifier(foe, with) >= 2 }

        handler.scene.visual.show_ability(with)
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 436, with))
      end
    end

    # Forewarn
    SwitchHandler.register_switch_event_hook('PSDK switch: Forewarn') do |handler, _, with|
      next unless with.has_ability?(:forewarn)

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
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 433, danger_foe, PFM::Text::MOVE[1] => danger_move.name))
    end

    # Frisk
    SwitchHandler.register_switch_event_hook('PSDK switch: Frisk') do |handler, _, with|
      next unless with.has_ability?(:frisk)

      foe_item = handler.logic.foes_of(with).find { |foe| foe.alive? && foe.battle_item_db_symbol != :__undef__ }
      next unless foe_item

      handler.scene.visual.show_ability(with)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 439, with, PFM::Text::PKNICK[1] => foe_item.given_name,
                                                                           PFM::Text::ITEM2[2] => foe_item.item_name))
    end

    # Download
    SwitchHandler.register_switch_event_hook('PSDK Switch: Download') do |handler, _, with|
      next unless with.has_ability?(:download)

      random_foe = handler.logic.foes_of(with).shuffle.find(&:alive?)
      next unless random_foe

      handler.scene.visual.show_ability(with)
      handler.logic.stat_change_handler.stat_change_with_process(random_foe.dfe < random_foe.dfs ? :atk : :ats, 1, with)
    end

    # Air Lock
    SwitchHandler.register_switch_event_hook('PSDK Switch: Air Lock') do |handler, _, with|
      next if $env.current_weather == 0
      next unless with.has_ability?(:air_lock)

      handler.scene.visual.show_ability(with)
      handler.logic.weather_change_handler.weather_change(:none, 0)
    end

    # Cloud Nine
    SwitchHandler.register_switch_event_hook('PSDK Switch: Cloud Nine') do |handler, _, with|
      next if $env.current_weather == 0
      next unless with.has_ability?(:cloud_nine)

      handler.scene.visual.show_ability(with)
      handler.logic.weather_change_handler.weather_change(:none, 0)
    end

    # Zen Mode
    SwitchHandler.register_switch_event_hook('PSDK Switch: Zen Mode') do |handler, _, with|
      next unless with.has_ability?(:zen_mode)

      original_form = with.form
      with.form_calibrate(:battle)
      if with.form != original_form
        handler.scene.visual.show_ability(with)
        handler.scene.visual.show_switch_form_animation(with)
        handler.scene.display_message_and_wait(parse_text(18, with.form.odd? ? 191 : 192))
      end
    end

    SwitchHandler.register_switch_event_hook('PSDK Switch: Zen Mode going out') do |_, who|
      next unless who.has_ability?(:zen_mode)

      who.form_calibrate # No argument here to force back the original form
    end

    # Electric Surge
    SwitchHandler.register_switch_event_hook('PSDK switch: Electric Surge') do |handler, _, with|
      next if with.ability_db_symbol != :electric_surge

      fterrain_handler = handler.logic.fterrain_change_handler
      next unless fterrain_handler.fterrain_appliable?(:electric_terrain)

      nb_turn = 5
      fterrain_handler.fterrain_change(:electric_terrain, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.display_message_and_wait(parse_text(18, 209))
    end

    # Grassy Surge
    SwitchHandler.register_switch_event_hook('PSDK switch: Grassy Surge') do |handler, _, with|
      next if with.ability_db_symbol != :grassy_surge

      fterrain_handler = handler.logic.fterrain_change_handler
      next unless fterrain_handler.fterrain_appliable?(:grassy_terrain)

      nb_turn = 5
      fterrain_handler.fterrain_change(:grassy_terrain, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.display_message_and_wait(parse_text(18, 205))
    end

    # Misty Surge
    SwitchHandler.register_switch_event_hook('PSDK switch: Misty Surge') do |handler, _, with|
      next if with.ability_db_symbol != :misty_surge

      fterrain_handler = handler.logic.fterrain_change_handler
      next unless fterrain_handler.fterrain_appliable?(:misty_terrain)

      nb_turn = 5
      fterrain_handler.fterrain_change(:misty_terrain, nb_turn)
      handler.scene.visual.show_ability(with)
      handler.scene.display_message_and_wait(parse_text(18, 207))
    end

    # Psychic Surge
    SwitchHandler.register_switch_event_hook('PSDK switch: Psychic Surge') do |handler, _, with|
      next if with.ability_db_symbol != :psychic_surge

      fterrain_handler = handler.logic.fterrain_change_handler
      next unless fterrain_handler.fterrain_appliable?(:psychic_terrain)

      nb_turn = 5
      # TODO: Add gen7 text of Psychic Terrain"
      fterrain_handler.fterrain_change(:psychic_terrain, nb_turn)
      handler.scene.visual.show_ability(with)
    end
  end
end
