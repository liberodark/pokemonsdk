module Battle
  class Move
    # Tell if forced next move decreases PP
    # @return [Boolean]
    attr_accessor :forced_next_move_decrease_pp

    # Show the effectiveness message
    # @param effectiveness [Numeric]
    # @param target [PFM::PokemonBattler]
    def efficent_message(effectiveness, target)
      if effectiveness > 1
        scene.display_message_and_wait(parse_text_with_pokemon(19, 6, target))
      elsif effectiveness > 0 && effectiveness < 1
        scene.display_message_and_wait(parse_text_with_pokemon(19, 15, target))
      end
    end

    # Show the usage failure when move is not usable by user
    # @param user [PFM::PokemonBattler] user of the move
    def show_usage_failure(user)
      usage_message(user)
      scene.display_message_and_wait(parse_text(18, 74))
    end

    # Function starting the move procedure
    # @param user [PFM::PokemonBattler] user of the move
    # @param target_bank [Integer] bank of the target
    # @param target_position [Integer]
    def proceed(user, target_bank, target_position)
      return if user.hp <= 0

      @damage_dealt = 0
      possible_targets = battler_targets(user, logic).select { |target| target&.alive? }
      possible_targets.sort_by(&:spd)
      return proceed_one_target(user, possible_targets, target_bank, target_position) if one_target?

      # Sort target by decreasing spd
      possible_targets.reverse!
      # Choose the right bank if user could choose bank
      possible_targets.select! { |pokemon| pokemon.bank == target_bank } unless no_choice_skill?

      specific_procedure = check_specific_procedure(user, possible_targets)
      return send(specific_procedure, user, possible_targets) if specific_procedure

      return proceed_internal(user, possible_targets)
    end

    # Proceed the procedure before any other attack.
    # @param user [PFM::PokemonBattler]
    def proceed_pre_attack(user)
      nil && user
    end

    private

    # Function starting the move procedure for 1 target
    # @param user [PFM::PokemonBattler] user of the move
    # @param possible_targets [Array<PFM::PokemonBattler>] expected targets
    # @param target_bank [Integer] bank of the target
    # @param target_position [Integer]
    def proceed_one_target(user, possible_targets, target_bank, target_position)
      right_target = possible_targets.find { |pokemon| pokemon.bank == target_bank && pokemon.position == target_position }
      right_target ||= possible_targets.find { |pokemon| pokemon.bank == target_bank && (pokemon.position - target_position).abs == 1 }
      right_target ||= possible_targets.find { |pokemon| pokemon.bank == target_bank }
      right_target = target_redirected(user, right_target)

      specific_procedure = check_specific_procedure(user, [right_target].compact)
      return send(specific_procedure, user, [right_target].compact) if specific_procedure

      return proceed_internal(user, [right_target].compact)
    end

    # Internal procedure of the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def proceed_internal(user, targets)
      return user.add_move_to_history(self, targets) unless (actual_targets = proceed_internal_precheck(user, targets))

      post_accuracy_check_effects(user, actual_targets)

      post_accuracy_check_move(user, actual_targets)

      play_animation(user, targets)

      deal_damage(user, actual_targets) &&
        effect_working?(user, actual_targets) &&
        deal_status(user, actual_targets) &&
        deal_stats(user, actual_targets) &&
        deal_effect(user, actual_targets)

      user.add_move_to_history(self, actual_targets)
      user.add_successful_move_to_history(self, actual_targets)
      @scene.visual.set_info_state(:move_animation)
      @scene.visual.wait_for_animation
    end

    # Internal procedure of the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [Array<PFM::PokemonBattler, nil] list of the right target to the move if success
    # @note this function is responsive of calling on_move_failure and checking all the things related to target/user in regard of move usability
    # @note it is forbiden to change anything in this function if you don't know what you're doing, the && and || are not ther because it's cute
    def proceed_internal_precheck(user, targets)
      # rubocop:disable Lint/LiteralAsCondition
      return unless move_usable_by_user(user, targets) || (on_move_failure(user, targets, :usable_by_user) && false)

      usage_message(user)

      pre_accuracy_check_effects(user, targets)
      return scene.display_message_and_wait(parse_text(18, 106)) if targets.all?(&:dead?) && (on_move_failure(user, targets, :no_target) || true)
      if pp == 0 && !(user.effects.has?(&:force_next_move?) && !@forced_next_move_decrease_pp)
        return (scene.display_message_and_wait(parse_text(18, 85)) || true) && on_move_failure(user, targets, :pp) && nil
      end

      decrease_pp(user, targets)
      # => proceed_move_accuracy will call display message if failure
      return unless !(actual_targets = proceed_move_accuracy(user, targets)).empty? || (on_move_failure(user, targets, :accuracy) && false)

      user, actual_targets = proceed_battlers_remap(user, actual_targets)

      actual_targets = accuracy_immunity_test(user, actual_targets) # => Will call $scene.dislay_message for each accuracy fail
      return if actual_targets.none? && (on_move_failure(user, targets, :immunity) || true)

      return actual_targets
      # rubocop:enable Lint/LiteralAsCondition
    end

    # Test move accuracy
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [Array] the actual targets
    def proceed_move_accuracy(user, targets)
      if bypass_accuracy?(user, targets)
        log_data('# proceed_move_accuracy: bypassed')
        return targets
      end

      return targets.select do |target|
        accuracy_dice = logic.move_accuracy_rng.rand(100)
        hit_chance = chance_of_hit(user, target)
        log_data("# target= #{target}, # accuracy= #{hit_chance}, value = #{accuracy_dice} (testing=#{hit_chance > 0}, failure=#{accuracy_dice >= hit_chance})")
        if accuracy_dice >= hit_chance
          text = hit_chance > 0 ? 213 : 24
          scene.display_message_and_wait(parse_text_with_pokemon(19, text, target))
          next false
        end

        next true
      end
    end

    # Tell if the move accuracy is bypassed
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [Boolean]
    def bypass_accuracy?(user, targets)
      if targets.all? { |target| user.effects.get(:lock_on)&.target == target }
        log_data('# accuracy= 100 (:lock_on effect)')
        return true
      end
      return true if user.has_ability?(:no_guard) || targets.any? { |target| target.has_ability?(:no_guard) }
      return true if db_symbol == :blizzard && $env.hail?
      return true if accuracy <= 0

      return false
    end

    # Show the move usage message
    # @param user [PFM::PokemonBattler] user of the move
    def usage_message(user)
      @scene.visual.hide_team_info
      message = parse_text_with_pokemon(8999 - Studio::Text::CSV_BASE, 12, user, PFM::Text::PKNAME[0] => user.given_name, PFM::Text::MOVE[0] => name)
      scene.display_message_and_wait(message)
      PFM::Text.reset_variables
    end

    # Method that remap user and targets if needed
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [PFM::PokemonBattler, Array<PFM::PokemonBattler>] user, targets
    def proceed_battlers_remap(user, targets)
      # Snatch Case
      if snatchable? && logic.all_alive_battlers.any? { |pkm| pkm != user && pkm.effects.has?(:snatch) }
        snatcher = logic.all_alive_battlers.max_by { |pkm| pkm != user && pkm.effects.has?(:snatch) ? pkm.spd : -1 }
        snatcher.effects.get(:snatch).kill
        user.effects.add(Effects::Snatched.new(logic, user))
        logic.scene.display_message_and_wait(parse_text_with_2pokemon(19, 754, snatcher, user))
        return snatcher, [snatcher]
      end

      # Normal way
      return user, targets
    end

    # Method responsive testing accuracy and immunity.
    # It'll report the which pokemon evaded the move and which pokemon are immune to the move.
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [Array<PFM::PokemonBattler>]
    def accuracy_immunity_test(user, targets)
      return targets.select do |pokemon|
        if target_immune?(user, pokemon)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 210, pokemon))
          next false
        elsif move_blocked_by_target?(user, pokemon)
          next false
        end

        next true
      end
    end

    # Test if the target is immune
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Boolean]
    def target_immune?(user, target)
      return true if prankster_immunity?(user, target)
      return true if powder? && target.type_grass? && user != target
      return true if user != target && ability_immunity?(user, target)
      return false if status?
      return false if levitate_vs_moldbreaker?(user, target)

      types = definitive_types(user, target)
      @effectiveness = -1
      return calc_type_n_multiplier(target, :type1, types) == 0 ||
             calc_type_n_multiplier(target, :type2, types) == 0 ||
             calc_type_n_multiplier(target, :type3, types) == 0
    end

    # Test if the target has an immunity due to the type of move & ability
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Boolean]
    def ability_immunity?(user, target)
      logic.each_effects(target) do |e|
        return true if e.on_move_ability_immunity(user, target, self)
      end

      return false
    end

    # Levitate and mold breaker functionality
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Boolean]
    def levitate_vs_moldbreaker?(user, target)
      return false if user == target
      return false unless user.ability_effect.db_symbol == :mold_breaker
      return false unless target.ability_effect.db_symbol == :levitate

      return true
    end

    # Test if the target has an immunity to the Prankster ability due to its type
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Boolean]
    def prankster_immunity?(user, target)
      return false if user == target
      return false unless target.type_dark?
      return false unless user.ability_effect.db_symbol == :prankster

      return user.ability_effect.on_move_priority_change(user, 1, self) == 2
    end

    # Calls the pre_accuracy_check method for each effects
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def pre_accuracy_check_effects(user, targets)
      creatures = [user] + targets
      logic.each_effects(*creatures) do |e|
        e.on_pre_accuracy_check(logic, scene, targets, user, self)
      end
    end

    # Calls the post_accuracy_check method for each effects
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] expected targets
    def post_accuracy_check_effects(user, actual_targets)
      creatures = [user] + actual_targets
      logic.each_effects(*creatures) do |e|
        e.on_post_accuracy_check(logic, scene, actual_targets, user, self)
      end
    end

    # Decrease the PP of the move
    # @param user [PFM::PokemonBattler]
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def decrease_pp(user, targets)
      return if user.effects.has?(&:force_next_move?) && !@forced_next_move_decrease_pp

      self.pp -= 1
      self.pp -= 1 if @logic.foes_of(user).any? { |foe| foe.alive? && foe.has_ability?(:pressure) }
    end

    # Function which permit things to happen before the move's animation
    def post_accuracy_check_move(user, actual_targets)
      return true
    end

    # Play the move animation
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def play_animation(user, targets)
      play_substitute_swap_animation(user)
      return unless $options.show_animation

      @scene.visual.set_info_state(:move_animation)
      @scene.visual.wait_for_animation
      play_animation_internal(user, targets)
      @scene.visual.set_info_state(:move, targets + [user])
      @scene.visual.wait_for_animation
    end

    # Play the move animation when having substitute
    # @param user [PFM::PokemonBattler] user of the move
    def play_substitute_swap_animation(user)
      return unless user.effects.has?(:substitute)
      return if user.effects.has?(:out_of_reach_base)

      user.effects.get(:substitute).play_substitute_animation(:from)
    end

    # Play the move animation (only without all the decoration)
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def play_animation_internal(user, targets)
      animations = MoveAnimation.get(self, :first_use)
      if animations
        MoveAnimation.play(animations, @scene.visual, user, targets)
      else
        @scene.visual.show_move_animation(user, targets, self)
      end
    end

    # Function that deals the damage to the pokemon
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
    def deal_damage(user, actual_targets)
      return true
    end

    # Function applying recoil damage to the user
    # @param hp [Integer]
    # @param user [PFM::PokemonBattler]
    def recoil(hp, user)
      return false if user.has_ability?(:rock_head) && !%i[struggle shadow_rush shadow_end].include?(db_symbol)
      return special_recoil(hp, user) if user.has_ability?(:parental_bond)

      @logic.damage_handler.damage_change((hp / recoil_factor).to_i.clamp(1, Float::INFINITY), user)
      @scene.display_message_and_wait(parse_text_with_pokemon(19, 378, user))
    end

    # Function applying recoil damage to the user
    # @note Only for Parental Bond !!
    # @param hp [Integer]
    # @param user [PFM::PokemonBattler]
    def special_recoil(hp, user)
      if user.ability_effect.first_turn_recoil == 0
        user.ability_effect.first_turn_recoil = hp
        return false
      end

      hp += user.ability_effect.first_turn_recoil
      user.ability_effect.first_turn_recoil = 0

      @logic.damage_handler.damage_change((hp / recoil_factor).to_i.clamp(1, Float::INFINITY), user)
      @scene.display_message_and_wait(parse_text_with_pokemon(19, 378, user))
    end

    # Test if the effect is working
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
    # @return [Boolean]
    def effect_working?(user, actual_targets)
      exec_hooks(Move, :effect_working, binding)
      return true
    end

    # Array mapping the status effect to an action
    STATUS_EFFECT_MAPPING = %i[nothing poison paralysis burn sleep freeze confusion flinch toxic]

    # Function that deals the status condition to the pokemon
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
    def deal_status(user, actual_targets)
      return true if status_effects.empty?

      dice = @logic.generic_rng.rand(0...100)
      status = status_effects.find do |status_effect|
        next true if status_effect.luck_rate > dice

        dice -= status_effect.luck_rate
        next false
      end || status_effects[0]

      actual_targets.each do |target|
        @logic.status_change_handler.status_change_with_process(status.status, target, user, self)
      end
      return true
    end

    # Function that deals the stat to the pokemon
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
    def deal_stats(user, actual_targets)
      return true if battle_stage_mod.empty?

      actual_targets.each do |target|
        battle_stage_mod.each do |stage|
          next if stage.count == 0

          @logic.stat_change_handler.stat_change_with_process(stage.stat, stage.count, target, user, self)
        end
      end
      return true
    end

    # Function that deals the effect to the pokemon
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
    def deal_effect(user, actual_targets)
      return true # TODO
    end

    # Event called if the move failed
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity, :pp
    def on_move_failure(user, targets, reason)
      return false
    end

    # Function that execute another move (Sleep Talk, Metronome)
    # @param move [Battle::Move] has to be cloned before calling the method
    # @param target_bank [Integer]
    # @param target_position [Integer]
    def use_another_move(move, user, target_bank = nil, target_position = nil)
      if target_bank.nil? || target_position.nil?
        targets = move.battler_targets(user, @logic)
        if targets.any? { |target| target.bank != user.bank }
          choosen_target = targets.reject { |target| target.bank == user.bank }.first
        else
          choosen_target = targets.first
        end
        target_bank = choosen_target.bank
        target_position = choosen_target.position
      end
      action = Actions::Attack.new(@scene, move, user, target_bank, target_position)
      action.execute
    end

    # Return the new target if redirected or the initial target
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [PFM::PokemonBattler] the target
    def target_redirected(user, targets)
      logic.each_effects(*logic.adjacent_foes_of(user)) do |e|
        new_target = e.target_redirection(user, targets, self)
        return new_target if new_target
      end

      return targets
    end
  end
end
