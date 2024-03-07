module Battle
  class Move

    # Check if an Effects imposes a specific proceed_internal
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    # @return [Symbol, nil] the symbol of the proceed_internal to call, nil if no specific procedure
    def check_specific_procedure(user, targets)
      logic.each_effects(user) do |e|
        specific_procedure = e.specific_proceed_internal(user, targets, self)
        return specific_procedure if specific_procedure
      end

      return nil
    end

    # Internal procedure of the move for Parental Bond Ability
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def proceed_internal_parental_bond(user, targets)
      return user.add_move_to_history(self, targets) unless (actual_targets = proceed_internal_precheck(user, targets))

      post_accuracy_check_effects(user, actual_targets)

      post_accuracy_check_move(user, actual_targets)

      play_animation(user, targets)

      nb_loop = user.ability_effect&.number_of_attacks || 1
      nb_loop.times do |nb_attack|
        next unless nb_attack == 0 || ((one_target_from_zone_attack(user) || one_target?) && !multi_hit? && !status?)
        next @scene.display_message_and_wait(parse_text(18, 33, PFM::Text::NUMB[1] => nb_attack.to_s)) if targets.any?(&:dead?)

        if nb_attack >= 1
          user.ability_effect&.activated = true
          scene.visual.show_ability(user)
        end

        user.ability_effect.attack_number = nb_attack
        deal_damage(user, actual_targets) &&
          effect_working?(user, actual_targets) &&
          deal_status(user, actual_targets) &&
          deal_stats(user, actual_targets) &&
          (user.ability_effect&.first_effect_can_be_applied?(be_method) || nb_attack > 0) &&
          deal_effect(user, actual_targets)
      end

      @scene.display_message_and_wait(parse_text(18, 33, PFM::Text::NUMB[1] => nb_loop.to_s)) if user.ability_effect&.activated
      user.ability_effect&.activated = false

      user.add_move_to_history(self, actual_targets)
      user.add_successful_move_to_history(self, actual_targets)
      @scene.visual.set_info_state(:move_animation)
      @scene.visual.wait_for_animation
    end

    # Internal procedure of the move for Sheer Force Ability
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def proceed_internal_sheer_force(user, targets)
      return user.add_move_to_history(self, targets) unless (actual_targets = proceed_internal_precheck(user, targets))

      post_accuracy_check_effects(user, actual_targets)

      post_accuracy_check_move(user, actual_targets)

      play_animation(user, targets)

      user.ability_effect&.activated = true

      deal_damage(user, actual_targets) &&
        effect_working?(user, actual_targets) &&
        deal_status(user, actual_targets) &&
        deal_stats(user, actual_targets) &&
        deal_effect_sheer_force(user, actual_targets)

      user.ability_effect&.activated = false if user.has_ability?(:sheer_force)

      user.add_move_to_history(self, actual_targets)
      user.add_successful_move_to_history(self, actual_targets)
      @scene.visual.set_info_state(:move_animation)
      @scene.visual.wait_for_animation
    end

    # Function that deals the effect to the pokemon
    # @param user [PFM::PokemonBattler] user of the move
    # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
    def deal_effect_sheer_force(user, actual_targets)
      return false unless user.has_ability?(:sheer_force)
      return false unless user.ability_effect.excluded_db_symbol.include?(db_symbol)
      return false unless user.ability_effect.excluded_methods.include?(be_method)

      return deal_effect(user, actual_targets)
    end

    # Internal procedure of the move
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def proceed_internal_dancer(user, targets)
      proceed_internal(user, targets)

      last_move = user.move_history.last
      last_successful_move = user.successful_move_history&.last

      user.move_history.pop if last_move.move == self && last_move.current_turn?
      user.successful_move_history.pop if last_successful_move&.move == self && last_successful_move.current_turn?
    end
  end
end
