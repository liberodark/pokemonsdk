module Battle
  class Logic
    class DamageHandler < ChangeHandlerBase
      include Hooks
      # Function telling if a damage can be applied and how much
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @note Thing that prevents the damage from being applied should be defined using :damage_prevention Hook.
      # @return [Integer, false]
      def damage_appliable(hp, target, launcher = nil, skill = nil)
        log_data("# damage_appliable(#{hp}, #{target}, #{launcher}, #{skill})")
        return false if target.hp <= 0

        reset_prevention_reason
        exec_hooks(DamageHandler, :damage_prevention, binding)
        return hp
      rescue Hooks::ForceReturn => e
        log_data("# FR: damage_appliable #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      end

      # Function that actually deal the damage
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @param messages [Proc] messages shown right before the post processing
      def damage_change(hp, target, launcher = nil, skill = nil, &messages)        
        skill&.damage_dealt += hp
        @scene.visual.show_hp_animations([target], [-hp], [skill&.effectiveness], &messages)
        exec_hooks(DamageHandler, :post_damage, binding) if target.hp > 0
        exec_hooks(DamageHandler, :post_damage_death, binding) if target.hp <= 0
        target.add_damage_to_history(hp, launcher, skill, target.hp <= 0)
        log_data("# damage_change(#{hp}, #{target}, #{launcher}, #{skill}, #{target.hp <= 0})")
      rescue Hooks::ForceReturn => e
        log_data("# FR: damage_change #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      ensure
        @scene.visual.refresh_info_bar(target)
      end

      # Function that test if the damage can be dealt and deal the damage if so
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @param messages [Proc] messages shown right before the post processing
      def damage_change_with_process(hp, target, launcher = nil, skill = nil, &messages)
        return process_prevention_reason unless (hp = damage_appliable(hp, target, launcher, skill))

        process_prevention_reason # Ensure that things with damage change like substitute shows something
        damage_change(hp, target, launcher, skill, &messages)
      end

      # Function that drains a certain quantity of HP from the target and give it to the user
      # @param hp_factor [Integer] the division factor of HP to drain
      # @param target [PFM::PokemonBattler] target that get HP drained
      # @param launcher [PFM::PokemonBattler] launcher of a draining move/effect
      # @param skill [Battle::Move, nil] Potential move used
      # @param hp_overwrite [Integer, nil] for the number of hp drained by the move
      # @param drain_factor [Integer] the division factor of HP drained
      # @param messages [Proc] messages shown right before the post processing
      def drain(hp_factor, target, launcher, skill = nil, hp_overwrite: nil, drain_factor: 1, &messages)
        hp = hp_overwrite || (target.max_hp / hp_factor).clamp(0, Float::INFINITY)
        damage_change(hp, target, launcher, skill, &messages)
        # TODO: Add hooks for all those stuff
        if target.has_ability?(:liquid_ooze)
          @scene.visual.show_ability(target)
          damage_change(hp, launcher, launcher, nil)
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 457, launcher))
        elsif launcher.effects.has?(:heal_block)
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 890, launcher))
        elsif launcher.hp < launcher.max_hp
          hp = hp * 130 / 100 if launcher.hold_item?(:big_root)
          hp = hp * 3 / 2 if skill&.pulse? && launcher.has_ability?(:mega_launcher)
          @scene.visual.show_hp_animations([launcher], [hp / drain_factor])
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 905, target))
        end
      end

      # Function that test if the drain damages can be dealt and perform the drain if so
      # @param hp_factor [Integer] the division factor of HP to drain
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def drain_with_process(hp_factor, target, launcher, skill = nil)
        hp = (target.max_hp / hp_factor).clamp(0, Float::INFINITY)
        return process_prevention_reason unless (hp = damage_appliable(hp, target, launcher, skill))

        drain(hp_factor, target, launcher, skill, hp_overwrite: hp)
      end

      class << self
        # Function that registers a damage_prevention hook
        # @param reason [String] reason of the damage_prevention registration
        # @yieldparam handler [DamageHandler]
        # @yieldparam hp [Integer] number of hp (damage) dealt
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        # @yieldreturn [:prevent, Integer] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def register_damage_prevention_hook(reason)
          Hooks.register(DamageHandler, :damage_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:hp),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
            hook_binding.local_variable_set(:hp, result) if result.is_a?(Integer)
            force_return(false) if result == :prevent
          end
        end

        # Function that registers a post_damage hook (when target is still alive)
        # @param reason [String] reason of the post_damage registration
        # @yieldparam handler [DamageHandler]
        # @yieldparam hp [Integer] number of hp (damage) dealt
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        def register_post_damage_hook(reason)
          Hooks.register(DamageHandler, :post_damage, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:hp),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
          end
        end

        # Function that registers a post_damage_death hook (when target is KO)
        # @param reason [String] reason of the post_damage_death registration
        # @yieldparam handler [DamageHandler]
        # @yieldparam hp [Integer] number of hp (damage) dealt
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        def register_post_damage_death_hook(reason)
          Hooks.register(DamageHandler, :post_damage_death, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:hp),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
          end
        end
      end
    end

    # Effects
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Effects') do |handler, hp, target, launcher, skill|
      next handler.logic.each_effects(launcher, target) do |e|
        result = e.on_damage_prevention(handler, hp, target, launcher, skill)
        hp = result if result.is_a?(Integer)
        next result
      end || hp
    end
    DamageHandler.register_post_damage_hook('PSDK post damage: Effects') do |handler, hp, target, launcher, skill|
      handler.logic.each_effects(launcher, target) do |e|
        e.on_post_damage(handler, hp, target, launcher, skill)
      end
    end
    DamageHandler.register_post_damage_death_hook('PSDK post damage death: Effects') do |handler, hp, target, launcher, skill|
      handler.logic.each_effects(launcher, target) do |e|
        e.on_post_damage_death(handler, hp, target, launcher, skill)
      end
    end

    # Focus Band
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Focus Band') do |_, hp, target, _, skill|
      next unless skill

      next target.hp - 1 if hp >= target.hp && target.hold_item?(:focus_band) && bchance?(0.1)
    end

    # Focus Sash
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Focus Sash') do |handler, hp, target, _, skill|
      next unless skill
      next if hp < target.hp || target.hp != target.max_hp || !target.hold_item?(:focus_sash)

      handler.logic.item_change_handler.change_item(:none, true, target)
      next target.hp - 1
    end

    # Oran Berry
    DamageHandler.register_post_damage_hook('PSDK post damage: Oran Berry') do |handler, _, target|
      unnerve_foes = handler.logic.foes_of(target).select { |foe| foe.has_ability?(:unnerve) }
      next unless target.hold_item?(:oran_berry) && unnerve_foes.none?

      if target.hp_rate <= 0.5
        handler.scene.visual.show_item(target)
        handler.scene.visual.show_hp_animations([target], [10])
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => target.item_name))
        handler.logic.item_change_handler.change_item(:none, true, target)
      end
    end

    # Sitrus Berry
    DamageHandler.register_post_damage_hook('PSDK post damage: Sitrus Berry') do |handler, _, target|
      unnerve_foes = handler.logic.foes_of(target).select { |foe| foe.has_ability?(:unnerve) }
      next unless target.hold_item?(:sitrus_berry) && unnerve_foes.none?

      if target.hp_rate <= 0.5
        handler.scene.visual.show_item(target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => target.item_name))
        handler.logic.item_change_handler.change_item(:none, true, target)
      end
    end

    # Air Balloon
    DamageHandler.register_post_damage_hook('PSDK post damage: Air Balloon') do |handler, _, target|
      next unless target.hold_item?(:air_balloon)

      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 411, target))
      handler.logic.item_change_handler.change_item(:none, true, target)
    end

    # Luminous Moss
    DamageHandler.register_post_damage_hook('PSDK Post damage: Luminous Moss') do |handler, _, target, _, skill|
      next unless skill&.type_water? && target.hold_item?(:luminous_moss)

      handler.scene.visual.show_item(target)
      handler.logic.stat_change_handler.stat_change_with_process(:dfs, 1, target)
      handler.logic.item_change_handler.change_item(:none, true, target)
    end

    # Snowball
    DamageHandler.register_post_damage_hook('PSDK Post damage: Luminous Moss') do |handler, _, target, _, skill|
      next unless skill&.type_ice? && target.hold_item?(:snowball)

      handler.scene.visual.show_item(target)
      handler.logic.stat_change_handler.stat_change_with_process(:atk, 1, target)
      handler.logic.item_change_handler.change_item(:none, true, target)
    end

    # Damage update
    DamageHandler.register_post_damage_hook('PSDK Post damage: Damage Update') do |_, hp, target, launcher, skill|
      next unless skill && launcher

      target.last_hit_by_move = skill
    end

    # Destiny Bond
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Destiny Bond') do |handler, _, target, launcher, skill|
      next unless skill && target.effects.has?(:destiny_bond) && launcher != target && launcher
      next if handler.logic.allies_of(target).include?(launcher)

      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 629, target))
      handler.scene.visual.show_hp_animations([launcher], [-launcher.hp])
    end

    # OHKO Moves
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: OHKO Moves') do |handler, _, target, launcher, skill|
      next unless skill&.be_method == :s_ohko && launcher != target && launcher

      handler.scene.display_message_and_wait(parse_text(18, 100)) # "Its a one-hit KO!"
    end

    # Shell Bell
    DamageHandler.register_post_damage_hook('PSDK Post damage: Shell Bell') do |handler, hp, target, launcher, skill|
      next unless skill && launcher&.hold_item?(:shell_bell) && hp >= 8 && launcher != target

      handler.scene.visual.show_item(launcher)
      handler.scene.visual.show_hp_animations([launcher], [hp / 8])
    end

    # Rocky Helmet
    DamageHandler.register_post_damage_hook('PSDK Post damage: Rocky Helmet') do |handler, hp, target, launcher, skill|
      next unless skill&.direct? && launcher&.hold_item?(:rocky_helmet) && hp >= 6 && launcher != target

      handler.scene.visual.show_item(target)
      handler.scene.visual.show_hp_animations([launcher], [hp / 6])
    end

    # Red Card
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Red Card') do |handler, _, target, launcher, skill|
      next unless skill && launcher != target && target.hold_item?(:red_card) && handler.logic.can_battler_be_replaced?(launcher)

      handler.scene.visual.show_item(target)
      handler.logic.switch_request << { who: launcher }
    end

    # Eject button
    DamageHandler.register_post_damage_hook('PSDK Post damage: Eject button') do |handler, _, target, launcher, skill|
      next unless skill && launcher != target && target.hold_item?(:eject_button) && handler.logic.can_battler_be_replaced?(target)
      next unless handler.logic.switch_handler.can_switch?(target)

      handler.scene.visual.show_item(target)
      handler.logic.item_change_handler.change_item(:none, true, target)
      handler.logic.switch_request << { who: target }
    end

    # Sticky Barb
    DamageHandler.register_post_damage_hook('PSDK Post damage: Sticky Barb') do |handler, _, target, launcher, skill|
      next unless skill && target.hold_item?(:sticky_barb) && launcher != target

      if launcher.item_db_symbol == :__undef__
        handler.logic.item_change_handler.change_item(:sticky_barb, false, launcher)
        handler.logic.item_change_handler.change_item(:none, false, target)
      end
    end

    # King's Rock
    DamageHandler.register_post_damage_hook('PSDK Post damage: King’s Rock') do |handler, _, target, launcher, skill|
      next unless skill&.trigger_king_rock? && launcher&.hold_item?(:king’s_rock) && launcher != target && bchance?(0.1)

      handler.scene.visual.show_item(launcher)
      handler.logic.status_change_handler.status_change_with_process(:flinch, target)
    end

    # Razor Fang
    DamageHandler.register_post_damage_hook('PSDK Post damage: Razor Fang') do |handler, _, target, launcher, skill|
      next unless skill && launcher&.hold_item?(:razor_fang) && launcher != target && bchance?(0.1)

      handler.scene.visual.show_item(launcher)
      handler.logic.status_change_handler.status_change_with_process(:flinch, target)
    end

    # Illusion
    DamageHandler.register_post_damage_hook('PSDK Post damage: Illusion') do |handler, _, target, launcher, skill|
      next unless skill && launcher != target
      next unless target.original.ability_db_symbol == :illusion && target.transform

      target.transform = nil
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_switch_form_animation(target)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 478, target))
    end
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Illusion') do |_, _, target, launcher, skill|
      next unless skill && launcher != target
      next unless target.original.ability_db_symbol == :illusion && target.transform

      target.transform = nil
    end
  end
end
