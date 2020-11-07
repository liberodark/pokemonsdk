module Battle
  class Move
    # Function that tests if the user is able to use the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
    # @return [Boolean] if the procedure can continue
    def move_usable_by_user(user, targets)
      PFM::Text.set_variable(PFM::Text::PKNICK[0], user.given_name)
      PFM::Text.set_variable(PFM::Text::MOVE[1], name)
      exec_hooks(Move, :move_prevention_user, binding)
      return true
    rescue Hooks::ForceReturn => e
      return e.data
    ensure
      PFM::Text.reset_variables
    end

    # Function that tests if the targets blocks the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] expected target
    # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
    # @return [Boolean] if the target evade the move (and is not selected)
    def move_blocked_by_target?(user, target)
      exec_hooks(Move, :move_prevention_target, binding) if user != target
      return false
    rescue Hooks::ForceReturn => e
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

  # Mold Breaker
  Move.register_move_prevention_user_hook('PSDK Move prev user: Mold Breaker') do |user, _, _|
    next if user.ability_db_symbol != :mold_breaker

    user.ability_used = false
  end

  # Torment registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Torment') do |user, _, move|
    if user.battle_effect.has_torment_effect? && !user.last_successfull_move_is?(move.db_symbol)
      move.scene.display_message(parse_text_with_pokemon(19, 580, user))
      next :prevent
    end
  end

  # Gravity registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Gravity') do |user, _, move|
    if move.scene.logic.global_gravity? && move.gravity_affected?
      move.scene.display_message(parse_text_with_pokemon(19, 1092, user))
      next :prevent
    end
  end

  # Flinch registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Flinch') do |user, _, move|
    if user.battle_effect.has_afraid_effect?
      move.scene.visual.show_rmxp_animation(user, 476)
      move.scene.display_message(parse_text_with_pokemon(19, 363, user))
      next :prevent
    end
  end

  # Truant registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Truant') do |user, _, move|
    if user.ability_db_symbol == :truant && user.ability_used
      move.scene.display_message(parse_text_with_pokemon(19, 445, user))
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
        move.scene.display_message(parse_text_with_pokemon(19, 303, user))
      else
        move.scene.visual.show_rmxp_animation(user, 469 + user.status)
        move.scene.display_message(parse_text_with_pokemon(19, 288, user))
        next :prevent
      end
    else
      move.scene.display_message(parse_text_with_pokemon(19, 294, user))
    end
    user.cure
    move.scene.visual.refresh_info_bar(user)
  end

  # Paralysis state registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Paralysis') do |user, _, move|
    if user.paralyzed? && user.paralysis_check
      move.scene.visual.show_rmxp_animation(user, 469 + user.status)
      move.scene.display_message(parse_text_with_pokemon(19, 276, user))
      next :prevent
    end
  end

  # Sleep state registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Sleep') do |user, _, move|
    if user.asleep?
      if user.sleep_check
        move.scene.visual.show_rmxp_animation(user, 469 + user.status)
        move.scene.display_message(parse_text_with_pokemon(19, 309, user))
        next if GameData::Skill[move.db_symbol].sleeping_attack?

        next :prevent
      else
        move.scene.visual.refresh_info_bar(user)
        move.scene.display_message(parse_text_with_pokemon(19, 312, user))
      end
    end
  end

  # Powder registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Powder') do |user, _, move|
    if user.battle_effect.has_powder_effect? && move.type_fire?
      move.send(:usage_message, user)
      if user.ability_db_symbol == :magic_guard
        move.scene.display_message(parse_text(18, 74))
      else
        move.scene.visual.show_hp_animations([user], [-user.max_hp / 4])
        move.scene.display_message(parse_text(18, 259, PFM::Text::MOVE[0] => move.name))
      end
      next :prevent
    end
  end

  # Confusion registration
  Move.register_move_prevention_user_hook('PSDK Move prev user: Confusion') do |user, _, move|
    if user.confused?
      stat = user.confuse_check
      move.scene.visual.show_rmxp_animation(user, 475)
      move.scene.display_message(parse_text_with_pokemon(19, (stat == :cured ? 351 : 348), user))
      if stat == true
        hp = user.confuse_damage
        move.scene.visual.show_hp_animations([user], [-hp])
        move.scene.display_message(parse_text(18, 83))
        next :prevent
      end
    end
  end

  # Protect registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Protect') do |_, target, move|
    next false unless move.blocked_by?(target, :protect)

    move.scene.display_message(parse_text_with_pokemon(19, 523, target))
    next true
  end

  # Sap Sipper registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Sap Sipper') do |user, target, move|
    next false if target.ability_db_symbol != :sap_sipper || !move.type_grass? || move.db_symbol == :aromatherapy
    next unless user.can_be_lowered_or_canceled?

    move.scene.visual.show_ability(target)
    move.logic.stat_change_handler.stat_change_with_process(:atk, 1, target, user, move)
    next true
  end

  # Detect registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Detect') do |_, target, move|
    next false unless move.blocked_by?(target, :detect)

    move.scene.display_message(parse_text_with_pokemon(19, 523, target))
    next true
  end

  # Spiky Shield registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Spiky Shield') do |user, target, move|
    next false unless move.blocked_by?(target, :spiky_shield)

    move.scene.display_message(parse_text_with_pokemon(19, 523, target))
    move.scene.visual.show_hp_animations([user], [-hp]) if move.direct?
    next true
  end

  # King's Shield registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: King\'s Shield') do |user, target, move|
    next false unless move.blocked_by?(target, :king’s_shield)

    move.scene.display_message(parse_text_with_pokemon(19, 523, target))
    move.scene.logic.stat_change_handler.stat_change_with_process(:atk, -1, target, user, skill) if move.direct?
    next true
  end

  # Baneful Bunker registration
  Move.register_move_prevention_target_hook('PSDK Move prev target: Baneful Bunker') do |user, target, move|
    next false unless move.blocked_by?(target, :baneful_bunker)

    move.scene.display_message(parse_text_with_pokemon(19, 523, target))
    # TODO: Make a utility for changing status and use it!
    if move.direct? && user.can_be_poisoned? && user.status_poison
      move.scene.visual.show_rmxp_animation(user, 470)
      move.scene.display_message(parse_text_with_pokemon(19, 234, user))
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
    next unless user.can_be_lowered_or_canceled?(move.status? && actual_targets.any? { |target| target.ability_db_symbol == :magic_bounce })

    if move.affects_bank? # Send move back to user if affects the bank in order to apply the effect to the bank
      blocker = actual_targets.find { |target| target.ability_db_symbol == :magic_bounce }
      move.scene.visual.show_ability(blocker)
      actual_targets.clear << user
      next
    end

    # Send the moves back to the user if target has magic bounce
    actual_targets.map! do |target|
      next target unless target.ability_db_symbol == :magic_bounce

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
end
