module Battle
  class Logic
    # Handler responsive of answering properly status changes requests
    class StatusChangeHandler < ChangeHandlerBase
      include Hooks
      # List of status that cannot be overwritten by Synchro
      # @type [Array]
      NOT_OVERWRITTABLE = safe_const(:NOT_OVERWRITTABLE) do
        [GameData::States::POISONED, GameData::States::BURN, GameData::States::PARALYZED, GameData::States::TOXIC]
      end
      # List of status Synchronize is applying
      SYNCHRONIZED_STATUS = %i[poison toxic paralysis burn]
      # List of method to call in order to apply the status on the Pokemon
      STATUS_APPLY_METHODS = {
        poison: :status_poison,
        toxic: :status_toxic,
        confusion: :status_confuse,
        sleep: :status_sleep,
        freeze: :status_frozen,
        paralysis: :status_paralyze,
        burn: :status_burn,
        cure: :cure
      }
      # List of message ID when applying a status
      STATUS_APPLY_MESSAGE = { poison: 234, toxic: 237, confusion: 345, sleep: 306, freeze: 288, paralysis: 273, burn: 255 }
      # List of animation ID when applying a status
      STATUS_APPLY_ANIMATION = { poison: 470, toxic: 477, confusion: 475, sleep: 473, freeze: 474, paralysis: 471, burn: 472, flinch: 476 }
      # List of messages when leaf guard is active
      STATUS_LEAF_GUARD_MSG = { poison: 252, toxic: 252, sleep: 318, freeze: 300, paralysis: 285, burn: 270 }

      # Function telling if a status can be applyied
      # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @note Thing that prevents the status from being applyied should be defined using :status_prevention Hook.
      # @return [Boolean]
      def status_appliable?(status, target, launcher = nil, skill = nil)
        return false if target.hp <= 0

        reset_prevention_reason
        exec_hooks(StatusChangeHandler, :status_prevention, binding) if status != :cure
        return true
      rescue Hooks::ForceReturn => e
        return e.data
      end

      # Function that actually change the status
      # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @param message_overwrite [Integer] Index of the message to use if file 19 to apply the status (if there's specific reason)
      def status_change(status, target, launcher = nil, skill = nil, message_overwrite: nil)
        if status == :cure
          message_overwrite ||= cure_message_id(target)
          target.send(STATUS_APPLY_METHODS[status])
        else
          message_overwrite ||= STATUS_APPLY_MESSAGE[status]
          target.send(STATUS_APPLY_METHODS[status], true)
          @scene.visual.show_rmxp_animation(target, STATUS_APPLY_ANIMATION[status])
        end
        @scene.display_message(parse_text_with_pokemon(19, message_overwrite, target)) if message_overwrite
        exec_hooks(StatusChangeHandler, :post_status_change, binding)
      rescue Hooks::ForceReturn => e
        return e.data
      ensure
        @scene.visual.refresh_info_bar(target)
      end

      # Function that test if the change is possible and perform the change if so
      # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def status_change_with_process(status, target, launcher = nil, skill = nil, message_overwrite: nil)
        return process_prevention_reason unless status_appliable?(status, target, launcher, skill)

        status_change(status, target, launcher, skill, message_overwrite: message_overwrite)
        launcher&.last_successfull_move = skill.db_symbol if skill
      end

      private

      # Get the message ID for the curing message
      # @param target [PFM::PokemonBattler]
      # @return [Integer]
      def cure_message_id(target)
        if target.poisoned? || target.toxic?
          return 246
        elsif target.burn?
          return 264
        elsif target.frozen?
          return 294
        elsif target.paralyzed?
          return 279
        else # asleep
          return 312
        end
      end

      class << self
        # Function that registers a status_prevention hook
        # @param reason [String] reason of the status_prevention registration
        # @yieldparam handler [StatusChangeHandler]
        # @yieldparam status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        # @yieldreturn [:prevent, nil] :prevent if the status cannot be applied
        def register_status_prevention_hook(reason)
          Hooks.register(StatusChangeHandler, :status_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:status),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
            force_return(false) if result == :prevent
          end
        end

        # Function that registers a post_status_change hook
        # @param reason [String] reason of the post_status_change registration
        # @yieldparam handler [StatusChangeHandler]
        # @yieldparam status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @yieldparam target [PFM::PokemonBattler]
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @yieldparam skill [Battle::Move, nil] Potential move used
        def register_post_status_change_hook(reason)
          Hooks.register(StatusChangeHandler, :post_status_change, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:status),
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
          end
        end
      end
    end

    # Effects
    StatusChangeHandler.register_post_status_change_hook('PSDK post status: Effects') do |handler, status, target, launcher, skill|
      handler.logic.each_effects(target, launcher) do |effect|
        next effect.on_post_status_change(handler, status, target, launcher, skill)
      end
    end
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Effects') do |handler, status, target, launcher, skill|
      next handler.logic.each_effects(target, launcher) do |effect|
        next effect.on_status_prevention(handler, status, target, launcher, skill)
      end
    end

    # Steadfast ability
    StatusChangeHandler.register_post_status_change_hook('PSDK post status: Steadfast') do |handler, status, target|
      next if status != :flinch || target.hp <= 0 || target.ability_db_symbol != :steadfast

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change_with_process(:spd, 1, target)
    end

    # Inner Focus
    StatusChangeHandler.register_status_prevention_hook('PSDK post status: Inner Focus') do |handler, status, target, launcher|
      next if status != :flinch || target.hp <= 0 || target.ability_db_symbol != :inner_focus
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
      end
    end

    # Synchronize ability
    StatusChangeHandler.register_post_status_change_hook('PSDK post status: Synchronize') do |handler, status, target, launcher|
      next if launcher == target || !launcher || launcher.ability_db_symbol != :synchronize
      next if StatusChangeHandler::NOT_OVERWRITTABLE.include?(launcher.status)
      next unless StatusChangeHandler::SYNCHRONIZED_STATUS.include?(status)

      launcher.send(StatusChangeHandler::STATUS_APPLY_METHODS[status], true)
      handler.scene.display_message(parse_text_with_pokemon(19, 1159, launcher))
    end

    # Quick Feet ability
    StatusChangeHandler.register_post_status_change_hook('PSDK post status: Quick Feet') do |handler, status, target, launcher, skill|
      next if target.ability_db_symbol != :quick_feet || status == :cure
      next unless handler.logic.stat_change_handler.stat_increasable?(:spd, target, launcher, skill)

      handler.scene.visual.show_ability(target)
      handler.logic.stat_change_handler.stat_change(:spd, 1, target, launcher, skill)
    end

    # Already confused
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: confused') do |handler, status, target|
      next if status != :confuse || !target.confused?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 354, target))
      end
    end

    # Substitute effect
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Substitue') do |handler, status, target, launcher, skill|
      next if status == :cure || launcher == target || !skill || !target.battle_effect.has_substitute_effect?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 24, target))
      end
    end

    # Safeguard effect
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Safeguard') do |handler, status, target, launcher, skill|
      next true if status == :cure || launcher == target || !skill || !target.battle_effect.has_safe_guard_effect?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 842, target))
      end
    end

    # Flower Veil ability
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Safeguard') do |handler, status, target, launcher, skill|
      next if status == :cure || launcher == target || skill&.db_symbol == :rest

      allies = handler.logic.alive_battlers(target.bank)
      fv = allies.find { |ally| ally.ability_db_symbol == :flower_veil && ally.type_grass? }
      next unless fv && launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(fv)
        handler.scene.display_message(parse_text_with_pokemon(19, 1180, target))
      end
    end

    # Own Tempo
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Own Tempo') do |handler, status, target, launcher|
      next if status != :confuse || target.ability_db_symbol != :own_tempo
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 357, target))
      end
    end

    # Already sleeping
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: sleeping') do |handler, status, target|
      next if status != :sleep || !target.asleep?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 315, target))
      end
    end

    # Leaf Guard
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Leaf Guard') do |handler, status, target, launcher|
      msg_id = StatusChangeHandler::STATUS_LEAF_GUARD_MSG[status]
      next if !msg_id || !$env.sunny? || target.ability_db_symbol != :leaf_guard
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, msg_id, target))
      end
    end

    # Vital Spirit
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Vital Spirit') do |handler, status, target, launcher|
      next if status != :sleep || target.ability_db_symbol != :vital_spirit
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 318, target))
      end
    end

    # Insomnia
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Insomnia') do |handler, status, target, launcher|
      next if status != :sleep || target.ability_db_symbol != :insomnia
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 318, target))
      end
    end

    # Cannot fall asleep
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: can_be_asleep') do |handler, status, target, _, skill|
      next if status != :sleep || target.can_be_asleep? || skill&.db_symbol == :rest

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 318, target))
      end
    end

    # Already frozen
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: frozen') do |handler, status, target|
      next if status != :freeze || !target.frozen?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 297, target))
      end
    end

    # Magma Armor
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Magma Armor') do |handler, status, target, launcher|
      next if status != :freeze || target.ability_db_symbol != :magma_armor
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 300, target))
      end
    end

    # Cannot be frozen
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: can_be_frozen') do |handler, status, target, _, skill|
      next if status != :freeze || target.can_be_frozen?(skill&.type || 0)

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 300, target))
      end
    end

    # Already poisoned
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: poisoned') do |handler, status, target|
      next if status != :poison && status != :toxic || !target.poisoned?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 249, target))
      end
    end

    # Immunity
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Immunity') do |handler, status, target, launcher|
      next if status != :poison && status != :toxic || target.ability_db_symbol != :immunity
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 252, target))
      end
    end

    # Cannot be poisoned
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: can_be_poisoned') do |handler, status, target|
      next if status != :poison && status != :toxic || target.can_be_poisoned?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 252, target))
      end
    end

    # Already paralyzed
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: paralyzed') do |handler, status, target|
      next if status != :paralysis || !target.paralyzed?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 282, target))
      end
    end

    # Limber
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Limber') do |handler, status, target, launcher|
      next if status != :paralysis || target.ability_db_symbol != :limber
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 285, target))
      end
    end

    # Cannot be paralyzed
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: can_be_asleep') do |handler, status, target, _, skill|
      next if status != :paralysis || target.can_be_paralyzed? || skill&.db_symbol == :body_slam

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 285, target))
      end
    end

    # Already burnt
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: burn') do |handler, status, target|
      next if status != :burn || !target.burn?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 267, target))
      end
    end

    # Water Veil
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: Water Veil') do |handler, status, target, launcher|
      next if status != :burn || target.ability_db_symbol != :water_veil
      next unless launcher.can_be_lowered_or_canceled?

      next handler.prevent_change do
        handler.scene.visual.show_ability(target)
        handler.scene.display_message(parse_text_with_pokemon(19, 270, target))
      end
    end

    # Cannot be burn
    StatusChangeHandler.register_status_prevention_hook('PSDK status prev: can_be_burn') do |handler, status, target|
      next if status != :burn || target.can_be_burn?

      next handler.prevent_change do
        handler.scene.display_message(parse_text_with_pokemon(19, 270, target))
      end
    end
  end
end
