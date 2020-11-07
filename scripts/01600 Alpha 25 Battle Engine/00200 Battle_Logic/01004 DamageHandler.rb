module Battle
  class Logic
    class DamageHandler < ChangeHandlerBase
      include Hooks
      # List of abilities that are not affected by Mummy
      NO_MUMMY_ABILITIES = %i[schooling shields_down stance_change disguise comatose multitype zen_mode battle_bond rks_system mummy]
      # Function telling if a damage can be applied and how much
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @note Thing that prevents the damage from being applied should be defined using :damage_prevention Hook.
      # @return [Integer, false]
      def damage_appliable(hp, target, launcher = nil, skill = nil)
        return false if target.hp <= 0

        reset_prevention_reason
        exec_hooks(DamageHandler, :damage_prevention, binding)
        return hp
      rescue Hooks::ForceReturn => e
        return e.data
      end

      # Function that actually deal the damage
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def damage_change(hp, target, launcher = nil, skill = nil)
        @scene.visual.show_hp_animations([target], [-hp], [skill&.effectiveness]) # TODO: pass skill.effectiveness
        exec_hooks(DamageHandler, :post_damage, binding) if target.hp > 0
        exec_hooks(DamageHandler, :post_damage_death, binding) if target.hp <= 0
        recoil(hp, launcher) if hp > 0 && launcher && skill&.recoil?
      rescue Hooks::ForceReturn => e
        return e.data
      ensure
        @scene.visual.refresh_info_bar(target)
      end

      # Function that test if the damage can be dealt and deal the damage if so
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def damage_change_with_process(hp, target, launcher = nil, skill = nil)
        return process_prevention_reason unless (hp = damage_appliable(hp, target, launcher, skill))

        damage_change(hp, target, launcher, skill)
      end

      # Function that drains a certain quantity of HP from the target and give it to the user
      # @param hp_factor [Integer] the division factor of HP to drain
      # @param target [PFM::PokemonBattler] target that get HP drained
      # @param launcher [PFM::PokemonBattler] launcher of a draining move/effect
      # @param skill [Battle::Move, nil] Potential move used
      # @param hp_overwrite [Integer, nil] for the number of hp drained by the move
      def drain(hp_factor, target, launcher, skill = nil, hp_overwrite: nil)
        hp = hp_overwrite || (target.max_hp / hp_factor).clamp(0, Float::INFINITY)
        damage_change(hp, target, launcher, skill)
        # TODO: Add hooks for all those stuff
        if target.ability_db_symbol == :liquid_ooze
          @scene.visual.show_ability(target)
          damage_change(hp, launcher, launcher, nil)
        elsif launcher.effects.has?(:heal_block)
          @scene.display_message(parse_text_with_pokemon(19, 890, launcher))
        else
          hp = hp * 130 / 100 if launcher.battle_item_db_symbol == :big_root
          @scene.visual.show_hp_animations([launcher], [hp])
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
          handler.scene.display_message(parse_text_with_pokemon(19, 794, target))
        else
          target.battle_effect.last_damaging_skill = nil
          handler.scene.display_message(parse_text_with_pokemon(19, 791, target))
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

      next target.hp - 1 if hp >= target.hp && target.battle_item_db_symbol == :focus_band && rand(10) == 1
    end

    # Focus Sash
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Focus Sash') do |handler, hp, target, _, skill|
      next unless skill
      next if hp < target.hp || target.hp != target.max_hp || target.battle_item_db_symbol != :focus_sash

      handler.logic.item_change_handler.change_item(:none, true, target)
      next target.hp - 1
    end

    # Water Absorb
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Water Absorb') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && !target.battle_effect.has_heal_block_effect? && target.ability_db_symbol == :water_absorb
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 387, target))
      end
    end

    # Volt Absorb
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Volt Absorb') do |handler, _, target, launcher, skill|
      next unless skill&.type_electric? && !target.battle_effect.has_heal_block_effect? && target.ability_db_symbol == :volt_absorb
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
        handler.scene.display_message(parse_text_with_pokemon(19, 387, target))
      end
    end

    # Sturdy
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Sturdy') do |handler, hp, target, _, skill|
      next unless skill
      next if hp < target.hp || target.hp != target.max_hp || target.ability_db_symbol != :sturdy

      handler.scene.visual.show_ability(target)
      next target.hp - 1
    end

    # Lightning Rod
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Lightning Rod') do |handler, _, target, launcher, skill|
      next unless skill&.type_electric? && target.ability_db_symbol == :lightning_rod
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, target)
      end
    end

    # Storm Drain
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Storm Drain') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && target.ability_db_symbol == :storm_drain
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:ats, 1, target)
      end
    end

    # Motor Drive
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Motor Drive') do |handler, _, target, launcher, skill|
      next unless skill&.type_electric? && target.ability_db_symbol == :motor_drive
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.logic.stat_change_handler.stat_change_with_process(:spd, 1, target)
      end
    end

    # Flash Fire
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Flash Fire') do |handler, _, target, launcher, skill|
      next unless skill&.type_fire? && target.ability_db_symbol == :flash_fire
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        # TODO: Apply power boost properly!
        handler.scene.visual.show_ability(target)
        handler.logic.status_change_handler.status_change_with_process(:cure, target) if target.frozen?
      end
    end

    # Dry Skin
    DamageHandler.register_damage_prevention_hook('PSDK damage prev: Dry Skin') do |handler, _, target, launcher, skill|
      next unless skill&.type_water? && target.ability_db_symbol == :dry_skin
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
      end
    end

    # Oran Berry
    DamageHandler.register_post_damage_hook('PSDK post damage: Oran Berry') do |handler, _, target|
      next unless target.battle_item_db_symbol == :oran_berry

      if target.hp_rate <= 0.5
        handler.scene.visual.show_item(target)
        # TODO: Use item handler
        handler.scene.visual.show_hp_animations([target], [10])
        handler.scene.display_message(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => target.item_name))
      end
    end

    # Sitrus Berry
    DamageHandler.register_post_damage_hook('PSDK post damage: Sitrus Berry') do |handler, _, target|
      next unless target.battle_item_db_symbol == :sitrus_berry

      if target.hp_rate <= 0.5
        handler.scene.visual.show_item(target)
        # TODO: Use item handler
        handler.scene.visual.show_hp_animations([target], [target.max_hp / 4])
        handler.scene.display_message(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => target.item_name))
      end
    end

    # Air Balloon
    DamageHandler.register_post_damage_hook('PSDK post damage: Air Balloon') do |handler, _, target|
      next unless target.battle_item_db_symbol == :air_balloon

      handler.scene.display_message(parse_text_with_pokemon(19, 411, target))
      handler.logic.item_change_handler.change_item(:none, true, target)
    end

    # Luminous Moss
    DamageHandler.register_post_damage_hook('PSDK Post damage: Luminous Moss') do |handler, _, target, _, skill|
      next unless skill&.type_water? && target.battle_item_db_symbol == :luminous_moss

      handler.scene.visual.show_item(target)
      handler.logic.stat_change_handler.stat_change_with_process(:dfs, 1, target)
      handler.logic.item_change_handler.change_item(:none, true, target)
    end

    # Snowball
    DamageHandler.register_post_damage_hook('PSDK Post damage: Luminous Moss') do |handler, _, target, _, skill|
      next unless skill&.type_ice? && target.battle_item_db_symbol == :snowball

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

      handler.scene.display_message(parse_text_with_pokemon(19, 629, target))
      handler.scene.visual.show_hp_animations([launcher], [-launcher.hp])
    end

    # Grudge
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Grudge') do |handler, _, target, launcher, skill|
      next unless skill && target.battle_effect.has_grudge_effect? && launcher != target && launcher

      handler.scene.display_message(parse_text_with_pokemon(19, 635, launcher, PFM::Text::MOVE[1] => skill.name))
      skill.pp = 0
    end

    # Rage
    DamageHandler.register_post_damage_hook('PSDK Post damage: Rage') do |handler, _, target, _, skill|
      next unless skill && target.battle_effect.has_rage_effect?

      handler.scene.display_message(parse_text_with_pokemon(19, 536, target))
      handler.logic.stat_change_handler.stat_change_with_process(:atk, 1, target)
    end

    # Shell Bell
    DamageHandler.register_post_damage_hook('PSDK Post damage: Shell Bell') do |handler, hp, target, launcher, skill|
      next unless skill && launcher&.battle_item_db_symbol == :shell_bell && hp >= 8 && launcher != target

      handler.scene.visual.show_item(launcher)
      handler.scene.visual.show_hp_animations([launcher], [hp / 8])
    end

    # Sticky Barb
    DamageHandler.register_post_damage_hook('PSDK Post damage: Sticky Barb') do |handler, _, target, launcher, skill|
      next unless skill && target&.battle_item_db_symbol == :sticky_barb && launcher != target

      # TODO: Dont forget to add damage of Sticky Barb in the end turn procedure ;)
      if launcher.item_db_symbol == :__undef__
        handler.logic.item_change_handler.change_item(:sticky_barb, false, launcher)
        handler.logic.item_change_handler.change_item(:none, false, target)
      end
    end

    # King's Rock
    DamageHandler.register_post_damage_hook('PSDK Post damage: King’s Rock') do |handler, _, target, launcher, skill|
      next unless skill&.trigger_king_rock? && launcher&.battle_item_db_symbol == :king’s_rock && launcher != target && rand(10) == 0

      handler.logic.status_change_handler.status_change_with_process(:flinch, target)
    end

    # Razor Fang
    DamageHandler.register_post_damage_hook('PSDK Post damage: Razor Fang') do |handler, _, target, launcher, skill|
      next unless skill && launcher&.battle_item_db_symbol == :razor_fang && launcher != target && rand(10) == 0

      handler.logic.status_change_handler.status_change_with_process(:flinch, target)
    end

    # Stench
    DamageHandler.register_post_damage_hook('PSDK Post damage: Stench') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && rand(10) == 0 && launcher.hp > 0 && launcher.ability_db_symbol == :stench

      handler.scene.visual.show_ability(launcher)
      handler.logic.status_change_handler.status_change_with_process(:flinch, target)
    end

    # Static
    DamageHandler.register_post_damage_hook('PSDK Post damage: Static') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && rand(10) < 3 && launcher.hp > 0 && target.ability_db_symbol == :static
      next unless launcher.can_be_paralyzed?

      handler.scene.visual.show_ability(target)
      handler.logic.status_change_handler.status_change_with_process(:paralysis, target)
    end

    # Poison Point
    DamageHandler.register_post_damage_hook('PSDK Post damage: Poison Point') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && rand(10) < 3 && launcher.hp > 0 && target.ability_db_symbol == :poison_point
      next unless launcher.can_be_poisoned?

      handler.scene.visual.show_ability(target)
      handler.logic.status_change_handler.status_change_with_process(:poison, target)
    end

    # Flame Body
    DamageHandler.register_post_damage_hook('PSDK Post damage: Flame Body') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && rand(10) < 3 && launcher.hp > 0 && target.ability_db_symbol == :flame_body
      next unless launcher.can_be_burn?

      handler.scene.visual.show_ability(target)
      handler.logic.status_change_handler.status_change_with_process(:burn, target)
    end

    # Cute Charm
    DamageHandler.register_post_damage_hook('PSDK Post damage: Cute Charm') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && rand(10) < 3 && launcher.hp > 0 && target.ability_db_symbol == :cute_charm
      next unless launcher.gender * target.gender == 2 && launcher.effects.has?(:attract)

      handler.scene.visual.show_ability(target)
      launcher.effects.add(Effects::Attract.new(handler.logic, launcher, target))
      handler.scene.display_message(parse_text_with_pokemon(19, 327, launcher))
    end

    # Effect Spore
    DamageHandler.register_post_damage_hook('PSDK Post damage: Effect Spore') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.ability_db_symbol == :effect_spore
      next if (n = rand(10)) > 2

      status = %i[poison sleep paralysis][n]
      if handler.logic.status_change_handler.status_appliable?(status, target)
        handler.scene.visual.show_ability(target)
        handler.logic.status_change_handler.status_change(status, target)
      end
    end

    # Rough Skin
    DamageHandler.register_post_damage_hook('PSDK Post damage: Rough Skin') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.ability_db_symbol == :rough_skin
      damages = launcher.max_hp >= 8 ? launcher.max_hp/8 : 1

      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_hp_animations([launcher], [damages])
      text = parse_text_with_pokemon(19, 430, launcher, PFM::Text::PKNICK[0] => launcher.given_name)
      handler.scene.display_message(text)
    end

    # Iron Barbs
    DamageHandler.register_post_damage_hook('PSDK Post damage: Iron Barbs') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.ability_db_symbol == :iron_barbs
      damages = launcher.max_hp >= 8 ? launcher.max_hp/8 : 1

      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_hp_animations([launcher], [damages])
      text = parse_text_with_pokemon(19, 430, launcher, PFM::Text::PKNICK[0] => launcher.given_name)
      handler.scene.display_message(text)
    end

    # Aftermath
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Aftermath') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.ability_db_symbol == :aftermath
      next unless launcher.max_hp >= 4

      if launcher.can_be_lowered_or_canceled?
        next if handler.logic.allies_of(target).any? { |pkmn| pkmn && pkmn.hp > 0 && pkmn.ability_db_symbol == :damp }
        next if handler.logic.foes_of(target).any? { |pkmn| pkmn && pkmn.hp > 0 && pkmn.ability_db_symbol == :damp }
      end

      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_hp_animations([launcher], [launcher.max_hp / 4])
    end

    # Mummy
    DamageHandler.register_post_damage_hook('PSDK Post damage: Mummy') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.ability_db_symbol == :mummy
      next if DamageHandler::NO_MUMMY_ABILITIES.include?(launcher.ability_db_symbol)

      handler.scene.visual.show_ability(target)
      handler.scene.display_message(parse_text_with_pokemon(19, 405, launcher, ::PFM::Text::ABILITY[1] => target.ability_name))
      launcher.ability_current = GameData::Abilities.find_using_symbol(:mummy)
    end

    # Color Change
    DamageHandler.register_post_damage_hook('PSDK Post damage: Color Change') do |handler, _, target, launcher, skill|
      next unless skill&.direct? && launcher && launcher != target && launcher.hp > 0 && target.ability_db_symbol == :color_change
      next if target.type1 == skill.type1

      handler.scene.visual.show_ability(target)
      target.type1 = skill.type
      text = parse_text_with_pokemon(19, 899, target, PFM::Text::PKNICK[0] => target.given_name,
                                                      '[VAR TYPE(0001)]' => GameData::Type[skill.type].name)
      handler.scene.display_message(text)
    end
  end
end
