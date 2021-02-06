module Battle
  class Logic
    # Function that distribute the exp to all Pokemon and switch dead pokemon
    def battle_phase_end
      log_debug('Entering battle_phase_end')
      end_turn_handler.process_events
      log_debug('end_turn_handler called')
      # Add all dead enemy to the switch request
      @switch_request.concat(
        dead_enemy_battler_during_this_turn.map { |battler| { who: battler } }
      )
      log_data("Number of switch request (ennemy) : #{@switch_request.size}")
      # Add all dead actors to switch request
      turn = $game_temp.battle_turn
      @switch_request.concat(
        trainer_battlers.select { |battler| battler.last_battle_turn == turn && battler.dead? }.map { |battler| { who: battler } }
      )
      log_data("Number of switch request (enemy + actors) : #{@switch_request.size}")
      @switch_request.uniq! { |who:| who }
      battle_phase_switch_exp_check
      log_debug('battle_phase_switch_exp_check called')
      all_alive_battlers.each { |pokemon| pokemon.switching = false }
    end

    # Function that test the experience distribution
    def battle_phase_exp
      exp_distributions = {}
      # Distribute exp and add all enemy that are dead to switch request
      dead_enemy_battler_during_this_turn.each do |enemy|
        next if enemy.exp_distributed

        exp_distributions.merge!(distribute_exp_for(enemy)) do |_, old_val, new_val|
          old_val + new_val
        end
        enemy.exp_distributed = true
      end

      @scene.visual.show_exp_distribution(exp_distributions) if exp_distributions.any?
    end

    # Function that process the switches and give exp
    def battle_phase_switch_exp_check
      return unless can_battle_continue?

      log_debug('battle_phase_switch_exp_check working')
      battle_phase_exp
      during_end_of_turn = @actions.empty?
      @switch_request.each do |who:, with: nil|
        next Actions::Switch.new(@scene, who, with).execute if who && with

        log_data("Attempting to switch #{who}")
        next unless can_battler_be_replaced?(who)

        with = switch_choose_with(who)
        log_data("Pokemon switched with #{who} : #{with}")
        next unless with

        request_switch_to_trainer(with) if who.bank != 0 && during_end_of_turn
        Actions::Switch.new(@scene, who, with).execute
      end
      @switch_request.clear
    end

    # Function that process the battle end when Pokemon was caught
    def battle_phase_end_caught
      pokemon = alive_battlers(1).find { |enemy| @battle_info.caught_pokemon == enemy }
      @scene.visual.show_exp_distribution(distribute_exp_for(pokemon))
    end

    private

    # Function that guess who we should switch the pokemon with
    # @param who [PFM::PokemonBattler]
    # @return [PFM::PokemonBattler, nil]
    def switch_choose_with(who)
      if who.from_party?
        return nil if trainer_battlers.all?(&:dead?)

        return @scene.visual.show_pokemon_choice(true)
      end
      BattleEngine.set_actors(6.times.map { |i| battler(0, i) }.compact.map { |i| PFM::PokemonBattler24.new(i) }) # BE24
      BattleEngine.set_enemies(6.times.map { |i| battler(1, i) }.compact.map { |i| PFM::PokemonBattler24.new(i) }) # BE24
      new_enemy = PFM::IA.request_switch(who) # BE24
      return nil unless new_enemy

      return battler(who.bank, -new_enemy[1] - 1)
    end

    # Function that ask the player if he wants to switch
    # @param enemy [PFM::PokemonBattler]
    def request_switch_to_trainer(enemy)
      battlers = trainer_battlers
      who = battlers[0]
      if $options.battle_mode && @battle_info.vs_type == 1 && battlers.count(&:alive?) > 1 && can_battler_be_replaced?(who) && !who.dead?
        text = parse_text(
          18, 21,
          '[VAR 010E(0000)]' => @battle_info.trainer_class(enemy),
          '[VAR TRNAME(0001)]' => @battle_info.trainer_name(enemy),
          '[VAR 019E(0000)]' => "#{@battle_info.trainer_class(enemy)} #{@battle_info.trainer_name(enemy)}",
          '[VAR PKNICK(0002)]' => enemy.given_name
        )
        choice = @scene.display_message_and_wait(text, 1, text_get(11, 27), text_get(11, 28))
        if choice == 0 && (result = @scene.visual.show_pokemon_choice)
          Actions::Switch.new(@scene, who, result).execute if result != who
        end
      end
    end

    # Function that distribute experience for a dead Enemy Pokemon
    # @param enemy [PFM::PokemonBattler]
    # @return [Hash{ PFM::PokemonBattler => Integer }]
    def distribute_exp_for(enemy)
      return {} if @battle_info.disallow_exp?

      expable = trainer_battlers.reject { |receiver| receiver.max_level == receiver.level || receiver.dead? }
      base_exp = exp_base(enemy)
      global_multi_exp_factor = $bag.contain_item?(:"exp._share")

      if global_multi_exp_factor
        exp_data = expable.map do |receiver|
          exp = (base_exp * exp_multipliers(receiver)).floor
          exp /= (receiver.last_battle_turn != $game_temp.battle_turn ? 14 : 7)
          next [receiver, exp]
        end
      else
        fought_count = expable.count { |battler| battler.last_battle_turn == $game_temp.battle_turn && battler.alive? }.clamp(1, 6)
        multi_exp_count = expable.count { |battler| battler.item_db_symbol == :"exp._share" && battler.alive? } # TODO: Implement a switch for that: && GLOBAL_MULTI_EXP_ENABLED
        multi_exp_factor = exp_multi_exp_factor(multi_exp_count)
        fought_exp_factor = exp_fought_factor(multi_exp_count, fought_count)
        exp_data = expable.map do |receiver|
          exp = (base_exp * exp_multipliers(receiver)).floor
          if receiver.last_battle_turn != $game_temp.battle_turn # Did not fight this turn
            next [receiver, (exp / multi_exp_factor).to_i]
          else
            next [receiver, (exp / fought_exp_factor).to_i + (receiver.item_db_symbol == :"exp._share" ? exp / multi_exp_factor : 0).to_i]
          end
        end
      end
      return exp_data.to_h
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
      trade_factor = receiver.from_player? ? 1 : 1.5
      loyalty_factor = 1 # TODO: Implement loyalty
      evolution_factor = 1 # TODO: Implement evolution factor (can evolve on next level)
      return aura_factor * lucky_factor * trade_factor * loyalty_factor * evolution_factor
    end

    # Get the multi_exp factor
    # @param multi_exp_count [Integer] number of Pokemon with multi_exp
    # @return [Integer]
    def exp_multi_exp_factor(multi_exp_count)
      return 14 * (multi_exp_count + 1)
    end

    # Get the fought factor
    # @param multi_exp_count [Integer] number of Pokemon with multi_exp
    # @param fought [Integer] number of Pokemon that fought
    def exp_fought_factor(multi_exp_count, fought)
      return (multi_exp_count > 0 ? 14.0 : 7.0) / fought
    end
  end
end
