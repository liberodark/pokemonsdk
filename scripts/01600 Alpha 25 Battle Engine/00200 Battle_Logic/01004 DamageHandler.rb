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
        log_data("# damage_change(#{hp}, #{target}, #{launcher}, #{skill})")
        skill&.damage_dealt += hp
        @scene.visual.show_hp_animations([target], [-hp], [skill&.effectiveness], &messages)
        exec_hooks(DamageHandler, :post_damage, binding) if target.hp > 0
        exec_hooks(DamageHandler, :post_damage_death, binding) if target.hp <= 0
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
    DamageHandler.register_post_damage_death_hook('PSDK post damage: Effects') do |handler, hp, target, launcher, skill|
      handler.logic.each_effects(launcher, target) do |e|
        e.on_post_damage(handler, hp, target, launcher, skill)
      end
    end

    # Substitute
    DamageHandler.register_damage_prevention_hook('PSDK damage perv: Substitute') do |handler, hp, target, _, skill|
      next if !skill || skill.sound_attack? || !target.battle_effect.has_substitute_effect?

      substitue_hp = target.battle_effect.substitute_hp
      hp -= substitue_hp
      handler.prevent_change do
        target.battle_effect.substitute_hp -= hp
        if hp > 0
          handler.scene.visual.show_switch_form_animation(target)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 794, target))
        else
          target.battle_effect.last_damaging_skill = nil
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 791, target))
        end
      end

      # We modify the HP if the substitute broke
      next hp <= 0 ? :prevent : hp
    end

    # Endure
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Endure') do |_, hp, target, _, skill|
      next unless skill

      next target.hp - 1 if target.battle_effect.has_endure_effect? && hp >= target.hp
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

    # Water Absorb
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Water Absorb') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && !target.effects.has?(:heal_block) && target.has_ability?(:water_absorb)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 387, target))
      end
    end

    # Volt Absorb
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Volt Absorb') do |handler, _, target, launcher, skill|
      next unless skill&.type_electric? && !target.effects.has?(:heal_block) && target.has_ability?(:volt_absorb)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 387, target))
      end
    end

    # Sturdy
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Sturdy') do |handler, hp, target, launcher, skill|
      next unless skill
      next if hp < target.hp || target.hp != target.max_hp || !target.has_ability?(:sturdy)
      next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      next target.hp - 1
    end

    # Lightning Rod
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Lightning Rod') do |handler, _, target, launcher, skill|
      next unless skill&.type_electric? && target.has_ability?(:lightning_rod)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, target)
      end
    end

    # Storm Drain
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Storm Drain') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && target.has_ability?(:storm_drain)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, target)
      end
    end

    # Motor Drive
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Motor Drive') do |handler, _, target, launcher, skill|
      next unless skill&.type_electric? && target.has_ability?(:motor_drive)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:spd, 1, target)
      end
    end

    # Flash Fire
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Flash Fire') do |handler, _, target, launcher, skill|
      next unless skill&.type_fire? && target.has_ability?(:flash_fire)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        # TODO: Apply power boost properly!
        handler.scene.visual.show_ability(target)
        handler.logic.status_change_handler.status_change_with_process(:cure, target) if target.frozen?
      end
    end

    # Dry Skin
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Dry Skin') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && target.has_ability?(:dry_skin)
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
      end
    end

    # Oran Berry
    DamageHandler.register_post_damage_hook('PSDK post damage: Oran Berry') do |handler, _, target|
      next unless target.hold_item?(:oran_berry)

      if target.hp_rate <= 0.5
        handler.scene.visual.show_item(target)
        handler.logic.item_change_handler.change_item(:none, true, target)
        handler.scene.visual.show_hp_animations([target], [10])
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => target.item_name))
      end
    end

    # Sitrus Berry
    DamageHandler.register_post_damage_hook('PSDK post damage: Sitrus Berry') do |handler, _, target|
      next unless target.hold_item?(:sitrus_berry)

      if target.hp_rate <= 0.5
        handler.scene.visual.show_item(target)
        handler.logic.item_change_handler.change_item(:none, true, target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => target.item_name))
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

      target.battle_effect.take_damages(hp, skill.atk_class, launcher)
      target.battle_effect.last_damaging_skill = skill # BE24
      target.last_hit_by_move = skill
    end

    # Destiny Bond
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Destiny Bond') do |handler, _, target, launcher, skill|
      next unless skill && target.last_successfull_move_is?(:destiny_bond) && launcher != target && launcher

      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 629, target))
      handler.scene.visual.show_hp_animations([launcher], [-launcher.hp])
    end

    # OHKO Moves
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: OHKO Moves') do |handler, _, target, launcher, skill|
      next unless skill&.be_method == :s_ohko && launcher != target && launcher

      handler.scene.display_message_and_wait(parse_text(18, 100)) # "Its a one-hit KO!"
    end

    # Grudge
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Grudge') do |handler, _, target, launcher, skill|
      next unless skill && target.battle_effect.has_grudge_effect? && launcher != target && launcher

      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 635, launcher, PFM::Text::MOVE[1] => skill.name))
      skill.pp = 0
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
      handler.logic.item_change_handler.change_item(:none, true)
      handler.logic.switch_request << { who: target }
    end

    # Sticky Barb
    DamageHandler.register_post_damage_hook('PSDK Post damage: Sticky Barb') do |handler, _, target, launcher, skill|
      next unless skill && target.hold_item?(:sticky_barb) && launcher != target

      # TODO: Dont forget to add damage of Sticky Barb in the end turn procedure ;)
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

    # Stench
    DamageHandler.register_post_damage_hook('PSDK Post damage: Stench') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && bchance?(0.1) && launcher.hp > 0 && launcher.has_ability?(:stench)

      handler.scene.visual.show_ability(launcher)
      handler.logic.status_change_handler.status_change_with_process(:flinch, target)
    end

    # Static
    DamageHandler.register_post_damage_hook('PSDK Post damage: Static') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && bchance?(0.3) && launcher.hp > 0 && target.has_ability?(:static)
      next unless launcher.can_be_paralyzed?

      handler.scene.visual.show_ability(target)
      handler.logic.status_change_handler.status_change_with_process(:paralysis, launcher)
    end

    # Pickpocket
    DamageHandler.register_post_damage_hook('PSDK Post damage: Pickpocket') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && target.has_ability?(:pickpocket)
      next if target.item_db_symbol != :__undef__
      next unless handler.logic.item_change_handler.can_lose_item?(launcher)

      handler.scene.visual.show_ability(target)
      handler.logic.item_change_handler.change_item(launcher.item_db_symbol, !$game_temp.trainer_battle, target)
      text = parse_text_with_pokemon(19, 460, launcher, PFM::Text::PKNICK[0] => launcher.given_name, PFM::Text::ITEM2[1] => launcher.item_name)
      handler.scene.display_message_and_wait(text)
      target.item_stolen = false
      if launcher.from_party?
        launcher.item_stolen = true
      else
        handler.logic.item_change_handler.change_item(:none, true, launcher)
      end
    end

    # Magician
    DamageHandler.register_post_damage_hook('PSDK Post damage: Magician') do |handler, _, target, launcher, _|
      next unless launcher && launcher != target && launcher.has_ability?(:magician)
      next if launcher.item_db_symbol != :__undef__
      next unless handler.logic.item_change_handler.can_lose_item?(target)

      handler.scene.visual.show_ability(launcher)
      handler.logic.item_change_handler.change_item(target.item_db_symbol, !$game_temp.trainer_battle, launcher)
      text = parse_text_with_pokemon(19, 1063, launcher, PFM::Text::PKNICK[0] => launcher.given_name,
                                                         PFM::Text::ITEM2[1] => target.item_name,
                                                         PFM::Text::PKNICK[1] => target.given_name)
      handler.scene.display_message_and_wait(text)
      launcher.item_stolen = false
      if target.from_party?
        target.item_stolen = true
      else
        handler.logic.item_change_handler.change_item(:none, true, target)
      end
    end

    # Poison Point
    DamageHandler.register_post_damage_hook('PSDK Post damage: Poison Point') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && bchance?(0.3) && launcher.hp > 0 && target.has_ability?(:poison_point)
      next unless launcher.can_be_poisoned?

      handler.scene.visual.show_ability(target)
      handler.logic.status_change_handler.status_change_with_process(:poison, launcher)
    end

    # Poison Touch
    DamageHandler.register_post_damage_hook('PSDK Post damage: Poison Touch') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && bchance?(0.3) && launcher.hp > 0 && launcher.has_ability?(:poison_touch)
      next unless target.can_be_poisoned?

      handler.scene.visual.show_ability(launcher)
      handler.logic.status_change_handler.status_change_with_process(:poison, target)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 472, target))
    end

    # Flame Body
    DamageHandler.register_post_damage_hook('PSDK Post damage: Flame Body') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && bchance?(0.3) && launcher.hp > 0 && target.has_ability?(:flame_body)
      next unless launcher.can_be_burn?

      handler.scene.visual.show_ability(target)
      handler.logic.status_change_handler.status_change_with_process(:burn, launcher)
    end

    # Cute Charm
    DamageHandler.register_post_damage_hook('PSDK Post damage: Cute Charm') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && bchance?(0.3) && launcher.hp > 0 && target.has_ability?(:cute_charm)
      next unless launcher.gender * target.gender == 2 && launcher.effects.has?(:attract)

      handler.scene.visual.show_ability(target)
      launcher.effects.add(Effects::Attract.new(handler.logic, launcher, target))
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 327, launcher))
    end

    # Effect Spore
    DamageHandler.register_post_damage_hook('PSDK Post damage: Effect Spore') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:effect_spore)
      next if (n = handler.logic.generic_rng.rand(10)) > 2

      status = %i[poison sleep paralysis][n]
      if handler.logic.status_change_handler.status_appliable?(status, target)
        handler.scene.visual.show_ability(target)
        handler.logic.status_change_handler.status_change(status, launcher)
      end
    end

    # Rough Skin
    DamageHandler.register_post_damage_hook('PSDK Post damage: Rough Skin') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:rough_skin)

      damages = launcher.max_hp >= 8 ? launcher.max_hp / 8 : 1
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_hp_animations([launcher], [-damages])
      text = parse_text_with_pokemon(19, 430, launcher, PFM::Text::PKNICK[0] => launcher.given_name)
      handler.scene.display_message_and_wait(text)
    end

    # Iron Barbs
    DamageHandler.register_post_damage_hook('PSDK Post damage: Iron Barbs') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:iron_barbs)

      damages = launcher.max_hp >= 8 ? launcher.max_hp / 8 : 1
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_hp_animations([launcher], [-damages])
      text = parse_text_with_pokemon(19, 430, launcher, PFM::Text::PKNICK[0] => launcher.given_name)
      handler.scene.display_message_and_wait(text)
    end

    # Aftermath
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Aftermath') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:aftermath)
      next unless launcher.max_hp >= 4

      if launcher.can_be_lowered_or_canceled?
        next if handler.logic.allies_of(target).any? { |pkmn| pkmn && pkmn.hp > 0 && pkmn.has_ability?(:damp) }
        next if handler.logic.foes_of(target).any? { |pkmn| pkmn && pkmn.hp > 0 && pkmn.has_ability?(:damp) }
      end

      damages = launcher.max_hp / 4
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_hp_animations([launcher], [-damages])
    end

    # Mummy
    DamageHandler.register_post_damage_hook('PSDK Post damage: Mummy') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:mummy)
      next unless handler.logic.ability_change_handler.can_change_ability?(launcher, :mummy)

      handler.scene.visual.show_ability(target)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 405, launcher, PFM::Text::ABILITY[1] => target.ability_name))
      handler.logic.ability_change_handler.change_ability(launcher, :mummy)
    end

    # Cursed Body
    DamageHandler.register_post_damage_hook('PSDK Post damage: Cursed Body') do |handler, _, target, launcher, skill|
      next unless launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:cursed_body)
      next if target.effects.has?(:substitute)

      handler.scene.visual.show_ability(target)
      launcher.effects.add(Effects::Disable.new(@logic, launcher, skill))
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 592, launcher, PFM::Text::MOVE[1] => skill.name))
    end

    # Rattled
    DamageHandler.register_post_damage_hook('PSDK Post Damage: Rattled') do |handler, _, target, launcher, skill|
      next unless launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:rattled)
      next unless skill.type_ghost? || skill.type_dark? || skill.type_bug?
      next if target.effects.has?(:substitute)

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:spd, 1, target)
    end

    # Wandering Spirit
    DamageHandler.register_post_damage_hook('PSDK Post damage: Wandering Spirit') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:wandering_spirit)
      next unless handler.logic.ability_change_handler.can_change_ability?(launcher, :wandering_spirit)

      handler.scene.visual.show_ability(target)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 405, launcher, PFM::Text::ABILITY[1] => target.ability_name))
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 405, target, PFM::Text::ABILITY[1] => launcher.ability_name))
      handler.logic.ability_change_handler.change_ability(launcher, :wandering_spirit)
      handler.logic.ability_change_handler.change_ability(target, PFM::Text::ABILITY[1] => target.ability_name)
    end

    # Color Change
    DamageHandler.register_post_damage_hook('PSDK Post damage: Color Change') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.has_ability?(:color_change)
      next if target.type1 == skill.type1

      handler.scene.visual.show_ability(target)
      target.type1 = skill.type
      text = parse_text_with_pokemon(19, 899, target, PFM::Text::PKNICK[0] => target.given_name,
                                                      '[VAR TYPE(0001)]' => GameData::Type[skill.type].name)
      handler.scene.display_message_and_wait(text)
    end

    # Disguise
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Disguise') do |handler, _, target, launcher, skill|
      next if target.effects.has?(:heal_block) || !target.has_ability?(:disguise) || skill.status?
      next unless launcher&.can_be_lowered_or_canceled?

      original_form = target.form
      target.form_calibrate(:battle)

      if target.form != original_form
        next handler.prevent_change do
          handler.scene.visual.show_ability(target)
          handler.scene.visual.show_switch_form_animation(target)
          handler.scene.visual.show_hp_animations([target], [-target.max_hp / 8])
        end
      end
    end

    # Disguise - Back to form 0 after death
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Disguise') do |_, _, target, _, _|
      next unless target&.has_ability?(:disguise)

      target&.form = 0
    end

    # Anger Point
    DamageHandler.register_post_damage_hook('PSDK Post damage: Anger Point') do |handler, _, target, launcher, skill|
      next unless skill&.critical_hit? && launcher && launcher != target && target.has_ability?(:anger_point)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:atk, 12, target)
    end

    # Gooey / Tangling Hair
    DamageHandler.register_post_damage_hook('PSDK Post damage: Gooey/Tangling Hair') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && (target.has_ability?(:gooey) || target.has_ability?(:tangling_hair))
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:spd, -1, launcher)
    end

    # Weak Armor
    DamageHandler.register_post_damage_hook('PSDK Post damage: Weak Armor') do |handler, _, target, launcher, skill|
      next unless skill&.physical? && launcher && launcher != target && target.has_ability?(:weak_armor)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:dfe, -1, target)
      handler.logic.stat_change_handler.stat_change_with_process(:spd, 2, target)
    end

    # Water Compaction
    DamageHandler.register_post_damage_hook('PSDK Post damage: Water Compaction') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && launcher && launcher != target && target.has_ability?(:water_compaction)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:dfe, 2, target)
    end

    # Steam Engine
    DamageHandler.register_post_damage_hook('PSDK Post damage: Steam Engine') do |handler, _, target, launcher, skill|
      next unless (skill&.type_water? || skill&.type_fire?) && launcher && launcher != target && target.has_ability?(:steam_engine)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:spd, 6, target)
    end

    # Berserk
    DamageHandler.register_post_damage_hook('PSDK Post damage: Bersek') do |handler, _, target, launcher, skill|
      next unless target.hp_rate <= 0.5 && skill && launcher && launcher != target && target.has_ability?(:berserk)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, target)
    end

    # Moxie
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Moxie') do |handler, _, target, launcher, skill|
      next unless launcher != target && launcher && skill
      # next unless target.can_be_lowered_or_canceled?

      handler.logic.allies_of(launcher).each do |ally|
        if launcher.has_ability?(:moxie) && target != ally
          handler.scene.visual.show_ability(launcher)
          handler.logic.stat_change_handler.stat_change_with_process(:atk, 1, launcher)
        end
      end
    end

    # Chilling Neigh
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Chilling Neigh') do |handler, _, target, launcher, skill|
      next unless launcher != target && launcher && skill
      # next unless target.can_be_lowered_or_canceled?

      handler.logic.allies_of(launcher).each do |ally|
        if launcher.has_ability?(:chilling_neigh) && target != ally
          handler.scene.visual.show_ability(launcher)
          handler.logic.stat_change_handler.stat_change_with_process(:atk, 1, launcher)
        end
      end
    end

    # Grim Neigh
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Grim Neigh') do |handler, _, target, launcher, skill|
      next unless launcher != target && launcher && skill
      # next unless target.can_be_lowered_or_canceled?

      handler.logic.allies_of(launcher).each do |ally|
        if launcher.has_ability?(:grim_neigh) && target != ally
          handler.scene.visual.show_ability(launcher)
          handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, launcher)
        end
      end
    end

    # Soul-Heart
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Soul-Heart') do |handler, _, target, launcher, _|
      next unless launcher != target && launcher
      # next unless target.can_be_lowered_or_canceled?

      if launcher.has_ability?(:"soul-heart")
        handler.scene.visual.show_ability(launcher)
        handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, launcher)
      end
    end

    # Stamina
    DamageHandler.register_post_damage_hook('PSDK Post damage: Stamina') do |handler, _, target, launcher, skill|
      next unless skill && launcher && launcher != target && target.has_ability?(:stamina)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:dfe, 1, target)
    end

    # Justified
    DamageHandler.register_post_damage_hook('PSDK Post damage: Justified') do |handler, _, target, launcher, skill|
      next unless skill&.type_dark? && launcher && launcher != target && target.has_ability?(:justified)
      # next unless launcher.can_be_lowered_or_canceled?

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:atk, 1, target)
    end

    # Sand Spit
    DamageHandler.register_post_damage_hook('PSDK Post Damage: Sand Spit') do |handler, _, target, launcher, skill|
      next unless skill && launcher && launcher != target && target.has_ability?(:sand_spit)

      weather_handler = handler.logic.weather_change_handler
      next unless weather_handler.weather_appliable?(:sandstorm)

      nb_turn = target.hold_item?(:smooth_rock) ? 8 : 5
      weather_handler.weather_change(:sandstorm, nb_turn)
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_rmxp_animation(target, 494)
    end

    # Cotton Down
    DamageHandler.register_post_damage_hook('PSDK Post damage: Cotton Down') do |handler, _, target, launcher, skill|
      next unless skill && launcher && launcher != target && target.has_ability?(:cotton_down)

      handler.logic.allies_of(target).each do |ally|
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:spd, -1, ally)
      end

      handler.logic.foes_of(target).each do |foe|
        handler.logic.stat_change_handler.stat_change_with_process(:spd, -1, foe)
      end
    end

    # Ice Face
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Ice Face') do |handler, _, target, launcher, skill|
      next if target.effects.has?(:heal_block) || !target.has_ability?(:ice_face)
      next unless skill&.physical?
      next unless launcher&.can_be_lowered_or_canceled?

      original_form = target.form
      target.form_calibrate(:battle)

      if target.form != original_form
        next handler.prevent_change do
          handler.scene.visual.show_ability(target)
          handler.scene.visual.show_switch_form_animation(target)
        end
      end
    end

    # Disguise - Back to form 0 after death
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Ice Face') do |_, _, target, _, _|
      next unless target&.has_ability?(:ice_face)

      target&.form = 0
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
