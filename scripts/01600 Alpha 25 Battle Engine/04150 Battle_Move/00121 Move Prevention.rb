module Battle
  class Move
    # List of choice item
    CHOICE_ITEMS = %i[choice_band choice_specs choice_scarf]
    # Function that tests if the user is able to use the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
    # @return [Boolean] if the procedure can continue
    def move_usable_by_user(user, targets)
      log_data("# move_usable_by_user(#{user}, #{targets})")
      PFM::Text.set_variable(PFM::Text::PKNICK[0], user.given_name)
      PFM::Text.set_variable(PFM::Text::MOVE[1], name)
      exec_hooks(Move, :move_prevention_user, binding)
      return true
    rescue Hooks::ForceReturn => e
      log_data("# FR: move_usable_by_user #{e.data} from #{e.hook_name} (#{e.reason})")
      return e.data
    ensure
      PFM::Text.reset_variables
    end

    # Function that tells if the move is disabled
    # @param user [PFM::PokemonBattler] user of the move
    # @return [Boolean]
    def disabled?(user)
      disable_reason(user) ? true : false
    end

    # Get the reason why the move is disabled
    # @param user [PFM::PokemonBattler] user of the move
    # @return [#call] Block that should be called when the move is disabled
    def disable_reason(user)
      return proc {} if pp == 0

      exec_hooks(Move, :move_disabled_check, binding)
      return nil
    rescue Hooks::ForceReturn => e
      log_data("# disable_reason(#{user})")
      log_data("# FR: disable_reason #{e.data} from #{e.hook_name} (#{e.reason})")
      return e.data
    end

    # Function that tests if the targets blocks the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] expected target
    # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
    # @return [Boolean] if the target evade the move (and is not selected)
    def move_blocked_by_target?(user, target)
      log_data("# move_blocked_by_target?(#{user}, #{target})")
      exec_hooks(Move, :move_prevention_target, binding) if user != target
      return false
    rescue Hooks::ForceReturn => e
      log_data("# FR: move_blocked_by_target? #{e.data} from #{e.hook_name} (#{e.reason})")
      return e.data
    end

    # Detect if the move is protected by another move on target
    # @param target [PFM::PokemonBattler]
    # @param symbol [Symbol]
    def blocked_by?(target, symbol)
      return blocable? && target.battle_effect.has_protect_effect? && target.last_successfull_move_is?(symbol)
    end

    class << self
      # Function that registers a move_prevention_user hook
      # @param reason [String] reason of the move_prevention_user registration
      # @yieldparam user [PFM::PokemonBattler]
      # @yieldparam targets [Array<PFM::PokemonBattler>]
      # @yieldparam move [Battle::Move]
      # @yieldreturn [:prevent, nil] :prevent if the move cannot continue
      def register_move_prevention_user_hook(reason)
        Hooks.register(Move, :move_prevention_user, reason) do |hook_binding|
          force_return(false) if yield(hook_binding.local_variable_get(:user), hook_binding.local_variable_get(:targets), self) == :prevent
        end
      end

      # Function that registers a move_disabled_check hook
      # @param reason [String] reason of the move_disabled_check registration
      # @yieldparam user [PFM::PokemonBattler]
      # @yieldparam move [Battle::Move]
      # @yieldreturn [Proc, nil] the code to execute if the move is disabled
      def register_move_disabled_check_hook(reason)
        Hooks.register(Move, :move_disabled_check, reason) do |hook_binding|
          result = yield(hook_binding.local_variable_get(:user), self)
          force_return(result) if result.respond_to?(:call)
        end
      end

      # Function that registers a move_prevention_target hook
      # @param reason [String] reason of the move_prevention_target registration
      # @yieldparam user [PFM::PokemonBattler]
      # @yieldparam target [PFM::PokemonBattler] expected target
      # @yieldparam move [Battle::Move]
      # @yieldreturn [Boolean] if the target is evading the move
      def register_move_prevention_target_hook(reason)
        Hooks.register(Move, :move_prevention_target, reason) do |hook_binding|
          force_return(true) if yield(hook_binding.local_variable_get(:user), hook_binding.local_variable_get(:target), self)
        end
      end
    end
  end

  # Effects
  Move.register_move_prevention_user_hook('PSDK Move prev user: Effects') do |user, targets, move|
    next move.logic.each_effects(user, *targets) do |effect|
      result = effect.on_move_prevention_user(user, targets, move)
      break result if result
    end
  end
  Move.register_move_prevention_target_hook('PSDK Move prev target: Effects') do |user, target, move|
    next move.logic.each_effects(user, target) do |effect|
      break true if effect.on_move_prevention_target(user, target, move) == true
    end == true
  end

  # Prevent unimplemented moves from being used
  Move.register_move_disabled_check_hook('PSDK .24 moves disabled') do |_, move|
    next if move.class != Battle::Move

    next proc { move.scene.display_message_and_wait('\c[2]This move is not implemented!\c[0]') }
  end

  # Choice item || Gorilla Tactics
  Move.register_move_disabled_check_hook('PSDK Move Disabled: Choice item') do |user, move|
    next unless Move::CHOICE_ITEMS.include?(user.battle_item_db_symbol) && user.move_history.any?
    next unless user.has_ability?(:gorilla_tactics) && user.move_history.any?
    next if user.move_history.last.db_symbol == move.db_symbol

    next proc {}
  end

  # Mold Breaker
  Move.register_move_prevention_user_hook('PSDK Move prev user: Mold Breaker') do |user, _, _|
    next unless user.has_ability?(:mold_breaker)

    user.ability_used = false
  end

  # Torment registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Torment') do |user, _, move|
    if user.battle_effect.has_torment_effect? && !user.last_successfull_move_is?(move.db_symbol)
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, 580, user))
      next :prevent
    end
  end
  Move.register_move_disabled_check_hook('PSDK Move disabled: Torment') do |user, move|
    next unless user.battle_effect.has_torment_effect? && !user.last_successfull_move_is?(move.db_symbol)

    next proc { move.scene.display_message_and_wait(parse_text_with_pokemon(19, 580, user)) }
  end

  # Assault vest
  Move.register_move_disabled_check_hook('PSDK Move disabled: Assault vest') do |user, move|
    next unless user.hold_item?(:assault_vest) && !move.status?

    next proc { move.scene.display_message_and_wait(parse_text_with_pokemon(19, 911, user, PFM::Text::MOVE[1])) }
  end

  # Gravity registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Gravity') do |user, _, move|
    if move.scene.logic.terrain_effects.has?(:gravity) && move.gravity_affected?
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, 1092, user))
      next :prevent
    end
  end

  # Truant registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Truant') do |user, _, move|
    if user.has_ability?(:truant) && user.ability_used
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, 445, user))
      user.ability_used = false
      next :prevent
    end
    user.ability_used = true
  end

  # Frozen state registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Frozen') do |user, _, move|
    next unless user.frozen?

    if user.froze_check
      if move.unfreeze?
        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 303, user))
      else
        move.scene.visual.show_rmxp_animation(user, 469 + user.status)
        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 288, user))
        next :prevent
      end
    else
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, 294, user))
    end
    user.cure
    move.scene.visual.refresh_info_bar(user)
  end

  # Paralysis state registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Paralysis') do |user, _, move|
    if user.paralyzed? && user.paralysis_check
      move.scene.visual.show_rmxp_animation(user, 469 + user.status)
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, 276, user))
      next :prevent
    end
  end

  # Sleep state registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Sleep') do |user, _, move|
    if user.asleep?
      if user.sleep_check
        move.scene.visual.show_rmxp_animation(user, 469 + user.status)
        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 309, user))
        next if GameData::Skill[move.db_symbol].sleeping_attack?

        next :prevent
      else
        move.scene.visual.refresh_info_bar(user)
        move.scene.display_message_and_wait(parse_text_with_pokemon(19, 312, user))
      end
    end
  end

  # Powder registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Powder') do |user, _, move|
    if user.battle_effect.has_powder_effect? && move.type_fire?
      move.send(:usage_message, user)
      if user.has_ability?(:magic_guard)
        move.scene.display_message_and_wait(parse_text(18, 74))
      else
        move.scene.visual.show_hp_animations([user], [-user.max_hp / 4])
        move.scene.display_message_and_wait(parse_text(18, 259, PFM::Text::MOVE[0] => move.name))
      end
      next :prevent
    end
  end

  # Confusion registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Confusion') do |user, _, move|
    if user.confused?
      stat = user.update_confuse_count
      move.scene.visual.show_rmxp_animation(user, 475) unless stat == :cured
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, (stat == :cured ? 351 : 348), user))
      if stat == true && bchance?(0.5) # 50% in Gen6 and 33% in Gen7
        hp = user.confuse_damage
        move.scene.visual.show_hp_animations([user], [-hp])
        move.scene.display_message_and_wait(parse_text(18, 83))
        next :prevent
      end
    end
  end

  # Protect registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Protect') do |_, target, move|
    next false unless move.blocked_by?(target, :protect)

    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
    next true
  end

  # Sap Sipper registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Sap Sipper') do |user, target, move|
    next false unless target.has_ability?(:sap_sipper) && move.type_grass? && move.db_symbol != :aromatherapy
    next unless user.can_be_lowered_or_canceled?

    move.scene.visual.show_ability(target)
    move.logic.stat_change_handler.stat_change_with_process(:atk, 1, target, user, move)
    next true
  end

  # Detect registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Detect') do |_, target, move|
    next false unless move.blocked_by?(target, :detect)

    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
    next true
  end

  # Spiky Shield registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Spiky Shield') do |user, target, move|
    next false unless move.blocked_by?(target, :spiky_shield)

    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
    move.scene.visual.show_hp_animations([user], [-hp]) if move.direct?
    next true
  end

  # King's Shield registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: King\'s Shield') do |user, target, move|
    next false unless move.blocked_by?(target, :king’s_shield)

    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
    move.scene.logic.stat_change_handler.stat_change_with_process(:atk, -1, target, user, skill) if move.direct?
    next true
  end

  # Baneful Bunker registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Baneful Bunker') do |user, target, move|
    next false unless move.blocked_by?(target, :baneful_bunker)

    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 523, target))
    # TODO: Make a utility for changing status and use it!
    if move.direct? && user.can_be_poisoned? && user.status_poison
      move.scene.visual.show_rmxp_animation(user, 470)
      move.scene.display_message_and_wait(parse_text_with_pokemon(19, 234, user))
    end
    next true
  end

  # Registers the magic bounce ability
  Hooks.register(Move, :effect_working, 'Magic Bounce Ability') do |move_binding|
    # @type [Battle::Move]
    move = self
    # @type [PFM::PokemonBattler]
    user = move_binding.local_variable_get(:user)
    # @type [Array<PFM::PokemonBattler>]
    actual_targets = move_binding.local_variable_get(:actual_targets)

    next if move.db_symbol == :memento
    next unless user.can_be_lowered_or_canceled?(move.status? && actual_targets.any? { |target| target.has_ability?(:magic_bounce) })

    if move.affects_bank? # Send move back to user if affects the bank in order to apply the effect to the bank
      blocker = actual_targets.find { |target| target.has_ability?(:magic_bounce) }
      move.scene.visual.show_ability(blocker)
      actual_targets.clear << user
      next
    end

    # Send the moves back to the user if target has magic bounce
    actual_targets.map! do |target|
      next target unless target.has_ability?(:magic_bounce)

      move.scene.visual.show_ability(target)
      next user
    end
  end

  Hooks.register(Move, :effect_working, 'Magic Coat effect') do |move_binding|
    # @type [Battle::Move]
    move = self
    # @type [PFM::PokemonBattler]
    user = move_binding.local_variable_get(:user)
    # @type [Array<PFM::PokemonBattler>]
    actual_targets = move_binding.local_variable_get(:actual_targets)

    next unless move.magic_coat_affected?
    next unless user.can_be_lowered_or_canceled?(move.status? && actual_targets.any? { |target| target.effects.has?(:magic_coat) })

    if move.affects_bank? # Send move back to user if affects the bank in order to apply the effect to the bank
      actual_targets.clear << user
      next
    end

    # Send the moves back to the user if target has magic bounce
    actual_targets.map! { |target| target.effects.has?(:magic_coat) ? user : target }
  end

  # Psychic Terrain effect
  Move.register_move_prevention_target_hook('PSDK Move prev target: Psychic Terrain') do |_, target, move|
    next false unless $env.terrain_psychic? && move.relative_priority >= 1 && move.blocable?

    # TODO: Add gen7 text of Psychic Terrain
    next true
  end

  # Queenly Majesty effect
  Move.register_move_prevention_target_hook('PSDK Move prev target: Queenly Majesty') do |user, target, move|
    protector = move.logic.foes_of(user).find { |pokemon| pokemon.has_ability?(:queenly_majesty) }
    next false unless protector && move.relative_priority >= 1 && move.blocable?

    move.scene.visual.show_ability(protector)
    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 911, user, "[VAR MOVE(0001)]" => move.name))

    next true
  end

  # Dazzling effect
  Move.register_move_prevention_target_hook('PSDK Move prev target: Dazzling') do |user, target, move|
    protector = move.logic.foes_of(user).find { |pokemon| pokemon.has_ability?(:dazzling) }
    next false unless protector && move.relative_priority >= 1 && move.blocable?

    move.scene.visual.show_ability(protector)
    move.scene.display_message_and_wait(parse_text_with_pokemon(19, 911, user, "[VAR MOVE(0001)]" => move.name))

    next true
  end
end
