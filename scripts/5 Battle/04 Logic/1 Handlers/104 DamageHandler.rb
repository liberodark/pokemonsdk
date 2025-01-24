module Battle
  class Logic
    # Handler responsive of defining how damage should be dealt (if possible)
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
        target.last_hit_by_move = skill if skill
        exec_hooks(DamageHandler, :post_damage, binding) if target.hp > 0
        if target.hp <= 0
          exec_hooks(DamageHandler, :post_damage_death, binding)
          target.ko_count += 1
        end
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

      # Function that proceed the heal of a Pokemon
      # @param target [PFM::PokemonBattler]
      # @param hp [Integer] number of HP to heal
      # @param test_heal_block [Boolean]
      # @param animation_id [Symbol, Integer] animation to use instead of the original one
      # @yieldparam hp [Integer] the actual hp healed
      # @return [Boolean] if the heal was successful or not
      # @note this method yields a block in order to show the message after the animation
      # @note this shows the default message if no block has been given
      def heal(target, hp, test_heal_block: true, animation_id: nil)
        if test_heal_block && target.effects.has?(:heal_block)
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 890, target))
          return false
        end

        if target.hp >= target.max_hp
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 896, target))
          return false
        end

        actual_hp = hp.clamp(1, target.max_hp - target.hp)
        # TODO: play the animation that should be played on all hp heal (+think about animation_id)
        target.position == -1 ? target.hp += actual_hp : @scene.visual.show_hp_animations([target], [actual_hp])
        if block_given?
          yield(actual_hp)
        else
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 387, target))
        end
        return true
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
        hp = hp_overwrite || (target.max_hp / hp_factor).clamp(1, Float::INFINITY)
        skill&.damage_dealt += hp
        @scene.visual.show_hp_animations([target], [-hp], [skill&.effectiveness], &messages)
        target.last_hit_by_move = skill if skill

        hp_multiplier = 1.0
        log_data("# drain hp_multiplier = #{hp_multiplier} before pre_drain hook")
        exec_hooks(DamageHandler, :pre_drain, binding)
        log_data("# drain hp_multiplier = #{hp_multiplier} after pre_drain hook")

        hp_healed = (hp * hp_multiplier / drain_factor).to_i.clamp(1, Float::INFINITY)
        exec_hooks(DamageHandler, :drain_prevention, binding)
        log_data("# drain drain_appliable? #{hp_healed > 0} after drain_prevention hook")

        @scene.display_message_and_wait(parse_text_with_pokemon(19, 905, target)) if hp_healed > 0 && launcher.alive? && heal(launcher, hp_healed)

        exec_hooks(DamageHandler, :post_damage, binding) if target.hp > 0
        if target.hp <= 0
          exec_hooks(DamageHandler, :post_damage_death, binding)
          target.ko_count += 1
        end

        target.add_damage_to_history(hp, launcher, skill, target.hp <= 0)
        log_data("# drain damage_change(#{hp}, #{target}, #{launcher}, #{skill}, #{target.hp <= 0})")
      rescue Hooks::ForceReturn => e
        log_data("# FR: drain damage_change #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      ensure
        @scene.visual.refresh_info_bar(target)
      end

      # Function that test if the drain damages can be dealt and perform the drain if so
      # @param hp_factor [Integer] the division factor of HP to drain
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @param hp_overwrite [Integer, nil] for the number of hp drained by the move
      # @param drain_factor [Integer] the division factor of HP drained
      # @param messages [Proc] messages shown right before the post processing
      def drain_with_process(hp_factor, target, launcher, skill = nil, hp_overwrite: nil, drain_factor: 1, &messages)
        hp = hp_overwrite || (target.max_hp / hp_factor).clamp(0, Float::INFINITY)
        return process_prevention_reason unless (hp = damage_appliable(hp, target, launcher, skill))

        drain(hp_factor, target, launcher, skill, hp_overwrite: hp, drain_factor: drain_factor, &messages)
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

        # Function that registers a pre_drain hook
        # @param reason [String] reason of the pre_drain registration
        # @yieldparam handler [DamageHandler]
        # @yieldparam hp [Integer] number of hp (damage) dealt
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        def register_pre_drain_hook(reason)
          Hooks.register(DamageHandler, :pre_drain, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:hp),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
            hook_binding.local_variable_set(:hp_multiplier, result) if result.is_a?(Numeric)
          end
        end

        # Function that registers a drain hook
        # @param reason [String] reason of the drain registration
        # @yieldparam handler [DamageHandler]
        # @yieldparam hp [Integer] number of hp (damage) dealt
        # @yieldparam hp_healed [Integer] number of hp healed
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        def register_drain_prevention_hook(reason)
          Hooks.register(DamageHandler, :drain_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:hp),
              hook_binding.local_variable_get(:hp_healed),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
            hook_binding.local_variable_set(:hp_healed, 0) if result == :prevent
          end
        end
      end
    end

    # Mummy's activation before other effects
    DamageHandler.register_post_damage_hook('PSDK post damage: Mummy') do |handler, hp, target, launcher, skill|
      next unless target.ability_effect.is_a?(Effects::Ability::Mummy)

      target.ability_effect.on_post_damage(handler, hp, target, launcher, skill)
      handler.pre_checked_effects << target.ability_effect
    end
    DamageHandler.register_post_damage_death_hook('PSDK post damage death: Mummy') do |handler, hp, target, launcher, skill|
      next unless target.ability_effect.is_a?(Effects::Ability::Mummy)

      target.ability_effect.on_post_damage_death(handler, hp, target, launcher, skill)
      handler.pre_checked_effects << target.ability_effect
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
        next if handler.pre_checked_effects.include?(e)

        next e.on_post_damage(handler, hp, target, launcher, skill)
      end
    end
    DamageHandler.register_post_damage_death_hook('PSDK post damage death: Effects') do |handler, hp, target, launcher, skill|
      handler.logic.each_effects(launcher, target) do |e|
        next if handler.pre_checked_effects.include?(e)

        next e.on_post_damage_death(handler, hp, target, launcher, skill)
      end
    end
    DamageHandler.register_pre_drain_hook('PSDK pre drain: Effects') do |handler, hp, target, launcher, skill|
      multiplier = 1.0
      handler.logic.each_effects(launcher, target) do |e|
        multiplier *= e.on_pre_drain(handler, hp, target, launcher, skill)
      end

      next multiplier
    end
    DamageHandler.register_drain_prevention_hook('PSDK drain prev: Effects') do |handler, hp, hp_healed, target, launcher, skill|
      handler.logic.each_effects(launcher, target) do |e|
        e.on_drain_prevention(handler, hp, hp_healed, target, launcher, skill)
      end
    end

    # Loyalty
    DamageHandler.register_post_damage_death_hook('PSDK post damage death: Loyalty update') do |_, _, target, launcher, _|
      next target.loyalty -= 1 unless launcher

      high_level_opponent = launcher.level - target.level >= 30
      low_loyalty = target.loyalty < 200
      if high_level_opponent
        target.loyalty -= low_loyalty ? 5 : 10
      else
        target.loyalty -= 1
      end
    end

    # Illusion
    DamageHandler.register_post_damage_hook('PSDK Post damage: Illusion') do |handler, _, target, launcher, skill|
      next unless skill && launcher != target
      next unless target.original.ability_db_symbol == :illusion && target.illusion

      target.illusion = nil
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_switch_form_animation(target)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 478, target))
    end
    DamageHandler.register_post_damage_death_hook('PSDK Post damage: Illusion') do |_, _, target, launcher, skill|
      next unless skill && launcher != target
      next unless target.original.ability_db_symbol == :illusion && target.illusion

      target.illusion = nil
    end

    # Critical hit count for Galarian Farfetch'd's evolution
    DamageHandler.register_post_damage_hook('PSDK post damage: ElvFarfetchD') do |_handler, _hp, _target, launcher, skill|
      next if launcher.nil?
      next unless launcher.evolution_condition_function?(:elv_sirfetchd)

      launcher.increase_evolve_var if skill.critical_hit?
    end
    DamageHandler.register_post_damage_death_hook('PSDK post damage: ElvFarfetchD') do |_handler, _hp, _target, launcher, skill|
      next if launcher.nil?
      next unless launcher.evolution_condition_function?(:elv_sirfetchd)

      launcher.increase_evolve_var if skill.critical_hit?
    end

    # Rage Fist usage count for Primeape's evolution into Annihilape
    DamageHandler.register_post_damage_hook('PSDK post damage: Rage Fist count') do |_handler, _hp, _target, launcher, skill|
      next if launcher.nil?
      next unless launcher.db_symbol == :primeape

      launcher.increase_evolve_var if skill.db_symbol == :rage_fist
    end
    DamageHandler.register_post_damage_death_hook('PSDK post damage: Rage Fist count') do |_handler, _hp, _target, launcher, skill|
      next if launcher.nil?
      next unless launcher.db_symbol == :primeape

      launcher.increase_evolve_var if skill.db_symbol == :rage_fist
    end
  end
end
