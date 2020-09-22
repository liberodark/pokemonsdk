module Battle
  class Logic
    # Function that distribute the exp to all Pokemon and switch dead pokemon
    def battle_phase_end
      # Distribute exp and add all enemy that are dead to switch request
      dead_enemy_battler_during_this_turn.each do |enemy|
        distribute_exp_for(enemy)
        @switch_request << { who: enemy }
      end
      # Add all actors to switch request
      turn = $game_temp.battle_turn
      @switch_request.concat(
        trainer_battlers.select { |battler| battler.last_battle_turn == turn && battler.dead? }.map { |battler| { who: battler } }
      )
      @switch_request.uniq! { |who:| who }
      battle_phase_switch_check
    end

    # Function that process the switches
    def battle_phase_switch_check
      return unless can_battle_continue?

      during_end_of_turn = @actions.empty?
      @switch_request.each do |who:, with: nil|
        next perform_action_switch(type: :switch, with: with, who: who) if who && with

        with = switch_choose_with(who)
        next unless with

        request_switch_to_trainer(who) if who.bank != 0 && during_end_of_turn
        perform_action_switch(type: :switch, with: with, who: who)
      end
      @switch_request.clear
    end

    private

    # Function that guess who we should switch the pokemon with
    # @param who [PFM::PokemonBattler]
    # @return [PFM::PokemonBattler, nil]
    def switch_choose_with(who)
      if who.from_party?
        return nil if trainer_battlers.all?(&:dead?)

        return @battle_scene.visual.show_pokemon_choice(true)
      end
      new_enemy = PFM::IA.request_switch(who) # BE24
      return nil unless new_enemy

      return battler(who.bank, -new_enemy[1] - 1)
    end

    # Function that ask the player if he wants to switch
    # @param enemy [PFM::PokemonBattler]
    def request_switch_to_trainer(enemy)
      battlers = trainer_battlers
      if $options.battle_mode && @battle_info.vs_type == 1 && battlers.count(&:alive?) > 1
        text = parse_text(
          18, 21,
          '[VAR 010E(0000)]' => @battle_info.trainer_class(enemy),
          '[VAR TRNAME(0001)]' => @battle_info.trainer_name(enemy),
          '[VAR 019E(0000)]' => "#{@battle_info.trainer_class(enemy)} #{@battle_info.trainer_name(enemy)}",
          '[VAR PKNICK(0002)]' => enemy.given_name
        )
        choice = @battle_scene.display_message(text, 1, text_get(11, 27), text_get(11, 28))
        if choice == 0 && (result = @battle_scene.visual.show_pokemon_choice)
          with = battlers.find { |battler| battler.original == result }
          who = battlers[0]
          perform_action_switch(type: :switch, with: result, who: who) if with != who
        end
      end
    end

    # Function that distribute experience for a dead Enemy Pokemon
    # @param enemy [PFM::PokemonBattler]
    def distribute_exp_for(enemy)
      expable = trainer_battlers
      base_exp = exp_base(enemy)
      global_multi_exp_factor = $bag.contain_item?(:"exp._share")

      if global_multi_exp_factor
        expable.each do |receiver|
          exp = (base_exp * exp_multipliers(receiver)).floor
          exp /= (receiver.last_battle_turn != $game_temp.battle_turn ? 14 : 7)
          distribute_exp_to(receiver, exp)
        end
      else
        fought_count = expable.count { |battler| battler.last_battle_turn == $game_temp.battle_turn && battler.alive? }.clamp(1, 6)
        multi_exp_count = expable.count { |battler| battler.item_db_symbol == :"exp._share" && battler.alive? } # TODO: Implement a switch for that: && GLOBAL_MULTI_EXP_ENABLED
        multi_exp_factor = exp_multi_exp_factor(multi_exp_count)
        fought_exp_factor = exp_fought_factor(multi_exp_count, fought_count)
        expable.each do |receiver|
          exp = (base_exp * exp_multipliers(receiver)).floor
          if receiver.last_battle_turn != $game_temp.battle_turn # Did not fight this turn
            distribute_exp_to(receiver, (exp / multi_exp_factor).to_i) if receiver.item_db_symbol == :"exp._share"
          else
            distribute_exp_to(receiver, (exp / fought_exp_factor).to_i + (receiver.item_db_symbol == :"exp._share" ? exp / multi_exp_factor : 0).to_i)
          end
        end
      end
    end

    # TODO: Move experience distribution in a dedicated class

    # Base exp
    # @param enemy [PFM::PokemonBattler]
    # @return [Float]
    def exp_base(enemy)
      return enemy.base_exp * enemy.level * (@battle_info.trainer_battle? ? 1.5 : 1)
    end

    # Exp multipliers
    # @param receiver [PFM::PokemonBattler]
    def exp_multipliers(receiver)
      aura_factor = 1 # TODO: Implement aura
      lucky_factor = receiver.item_db_symbol == :lucky_egg ? 1.5 : 1
      trade_factor = receiver.trainer_id != $trainer.id ? 1.5 : 1
      loyalty_factor = 1 # TODO: Implement loyalty
      evolution_factor = 1 # TODO: Implement evolution factor (can evolve on next level)
      return aura_factor * lucky_factor * trade_factor * loyalty_factor * evolution_factor
    end

    # Get the multi_exp factor
    # @param multi_exp_count [Integer] number of Pokemon with multi_exp
    # @return [Integer]
    def exp_multi_exp_factor(multi_exp_count)
      return 14 * multi_exp_count
    end

    # Get the fought factor
    # @param multi_exp_count [Integer] number of Pokemon with multi_exp
    # @param fought [Integer] number of Pokemon that fought
    def exp_fought_factor(multi_exp_count, fought)
      return (multi_exp_count > 0 ? 14.0 : 7.0) / fought
    end

    # Apply the last factor to

    # Function that perform the distribute exp phase to a receiver
    # @param receiver [PFM::PokemonBattler]
    # @param exp [Integer]
    def distribute_exp_to(receiver, exp)
      exp = exp.to_i
      display_exp_message(receiver, exp)
      show_animation = receiver.position < @battle_info.vs_type
      target_exp = receiver.exp + exp
      while target_exp > receiver.exp
        next_exp_value = receiver.exp_lvl.clamp(0, target_exp)
        @battle_scene.visual.show_exp_animation(receiver, next_exp_value) if show_animation # Show exp progression animation
        receiver.exp = next_exp_value
        next if receiver.exp < receiver.exp_lvl

        list = receiver.level_up_stat_refresh
        level_up_message(receiver, list) if show_animation || receiver.exp == target_exp || receiver.can_learn_skill_at_this_level?
      end
    end

    # Show the level up message
    # @param receiver [PFM::PokemonBattler]
    # @param list [Array]
    def level_up_message(receiver, list)
      PFM::Text.set_num3(receiver.level.to_s, 1)
      @battle_scene.visual.show_rmxp_animation(receiver, 497) if receiver.position < @battle_info.vs_type
      Audio.me_play('audio/me/rosa_levelup')
      @battle_scene.display_message(parse_text(18, 62, '[VAR 010C(0000)]' => receiver.given_name))
      @battle_scene.visual.refresh_info_bar(receiver) if receiver.position < @battle_info.vs_type
      PFM::Text.reset_variables
      receiver.level_up_window_call(list[0], list[1], @battle_scene.message_window.z + 5)
      receiver.check_skill_and_learn
      @evolve_request << receiver unless @evolve_request.include?(receiver)
    end

    # Function that display the "X received Y exp"
    # @param receiver [PFM::PokemonBattler]
    # @param exp [Integer]
    def display_exp_message(receiver, exp)
      text = parse_text(
        18, receiver.item_db_symbol == :"exp._share" ? 44 : 43,
        '[VAR 010C(0000)]' => receiver.given_name,
        PFM::Text::NUM7R => exp.to_s
      )
      @battle_scene.display_message(text)
    end
  end
end
