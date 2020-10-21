module BattleEngine
  class MessageInterpter
    private

    # Apply the attract effect
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @param nb_turn [Integer, Float::INFINITY]
    def attract_effect(launcher, target, nb_turn = Float::INFINITY)
      raise 'This effect should not be called like that'
    end

    # Apply flinch effect
    # @param target [PFM::PokemonBattler]
    def apply_flinch(target)
      return if @ignore || target.hp <= 0

      if Abilities.has_ability_usable(target, 19) # Inner Focus
        ability_display(target)
        return
      elsif Abilities.has_ability_usable(target, 86) # Steadfast
        ability_display(target)
        change_spd(target, 1)
      end
      target.battle_effect.apply_afraid
    end
    alias effect_afraid apply_flinch

    # Apply the powder effect
    # @param target [PFM::PokemonBattler]
    def powder_effect(target)
      return if @ignore || target.hp <= 0

      be = target.battle_effect
      be.apply_powder
      msg(parse_text_with_pokemon(19, 1210, target))
    end

    # Force the target to use a move for n turn
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    # @param nb_turn [Integer]
    def force_attack(launcher, target, skill, nb_turn)
      launcher.battle_effect.apply_forced_attack(skill.id, nb_turn, target)
    end

    # Force the Pokemon to rest for the next turn
    # @param target [PFM::PokemonBattler]
    def enter_reload_state(target)
      return if @ignore || target.hp <= 0

      target.battle_effect.set_reload_state(true)
    end
    alias set_reload_state enter_reload_state

    # Roar, ends the battle
    # @param target [PFM::PokemonBattler]
    def roar(target)
      @scene.battle_end(1)
    end

    # Apply the perish song effect on target
    # @param target [PFM::PokemonBattler]
    def perish_song(target)
      return if @ignore || target.hp <= 0

      target.battle_effect.apply_perish_song unless target.battle_effect.has_perish_song_effect?
    end

    # Do the jackpot effect
    # @param launcher [PFM::PokemonBattler]
    def jackpot(launcher)
      return if @ignore || launcher.hp <= 0

      log_error('jackpot is not ready yet!')
=begin
      n = 5
      #>Piece rune / Encens Veine
      n *= 2 if BattleEngine._has_item(launcher, 223) || BattleEngine._has_item(launcher, 319)
      @scene.money += launcher.level*n
=end
      msg(parse_text(18, 128))
    end

    # Apply the happy hour effect on the field
    # @param target [PFM::PokemonBattler]
    def happy_hour(target)
      return if @ignore || target.hp <= 0

      set_state(:happy_hour, true)
      msg(parse_text(18, 255))
    end

    # Apply the bind effect on the target
    # @param target [PFM::PokemonBattler]
    # @param launcher [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    # @param nb_turn [Integer]
    def bind(target, nb_turn, skill, launcher)
      return if @ignore || target.hp <= 0

      target.battle_effect.apply_bind(nb_turn, skill.name, launcher) unless target.battle_effect.has_bind_effect?
    end

    # Apply the leech seed effect
    # @param target [PFM::PokemonBattler]
    # @param launcher [PFM::PokemonBattler]
    def leech_seed(target, launcher)
      raise 'This effect is not supposed to be called!'
    end

    # Apply future skill effect
    # @param target [PFM::PokemonBattler]
    # @param hp [Integer]
    # @param nb_turn [Integer]
    # @param skill_id [Integer]
    def future_skill(target, hp, nb_turn, skill_id)
      log_error('Future skill is badly implemented, hp should be calculated on last turn!')
      target.battle_effect.set_future_skill(hp, nb_turn, skill_id)
      @launcher.battle_effect.set_future_wait(nb_turn)
    end

    # Apply an effect to the target
    # @param target [PFM::PokemonBattler]
    # @param effect [Symbol]
    # @param args [Array] effect argument
    def apply_effect(target, effect, *args)
      target.battle_effect.send(effect, *args)
    end

    # Reset the negative stat condition on target
    # @param target [PFM::PokemonBattler]
    def stat_reset_neg(target)
      bs = target.battle_stage
      bs.each_index do |i|
        bs[i] = 0 if bs[i] < 0
      end
    end

    # Reset all stat condition on target
    def stat_reset(target)
      bs = target.battle_stage
      bs.each_index do |i|
        bs[i] = 0
      end
    end

    # Apply a stat condition on target
    # @param target [PFM::PokemonBattler]
    # @param index [Integer] Index of the stat (use GameData::Stages to get the right index)
    # @param value [Integer] the forced value
    def stat_set(target, index, value)
      target.battle_stage[index] = value
    end

    # Force a type on the target
    # @param target [PFM::PokemonBattler]
    # @param type [Integer] ID of the type in the database (use GameData::Types)
    # @param index [Integer] index of the type (1, 2, 3)
    def set_type(target, type, index = 3)
      case index
      when 1
        target.type1 = type
      when 2
        target.type2 = type
      when 3
        target.type3 = type
      end
    end

    # Force the ability on the target
    # @param target [PFM::PokemonBattler]
    # @param ability [Integer, Symbol]
    def set_ability(target, ability)
      ability = GameData::Abilities.find_using_symbol(ability) if ability.is_a?(Symbol)
      target.ability_current = ability
    end

    # Set the Battle Effect value
    # @param target [PFM::PokemonBattler]
    # @param variable [Symbol]
    # @param value [Object]
    def set_be_value(target, variable, value)
      return if @ignore || target.hp <= 0

      target.battle_effect.send(variable, value.is_a?(PFM::PokemonBattler24) ? value.pokemon_battler : value)
    end

    # Switch the target to another pokemon
    # @param target [PFM::PokemonBattler]
    # @param to [PFM::PokemonBattler, nil] nil to let the player choose
    def switch_pokemon(target, to)
      return if @ignore || target.hp <= 0 || @target.hp <= 0

      log_error('Do not forget to implement the switch request at the end of the turn!')
      if to # Forced switch
        @logic.request_switch(target, to)
      elsif @logic.allies_of(target).count(&:alive?) > 0
        @logic.request_switch(target, nil)
      end
    end

    # Apply sketch on a move
    # @param launcher [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    # @param id [Integer] ID of the move
    def sketch(launcher, skill, id)
      return if @ignore || @target.hp <= 0

      (skill.original || skill).switch(id, 0, true)
    end

    # Apply the mirror move effect
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    # @param id [Integer] ID of the move
    def mimic(launcher, target, skill, id)
      return if @ignore || target.hp <= 0

      (skill.original || skill).switch(id)
      target.battle_effect.apply_mimic(launcher, (skill.original || skill))
    end

    # Decrease the PP on a move
    # @param target [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    # @param pp [Integer]
    def pp_down(target, skill, pp)
      return if @ignore || target.hp <= 0

      (skill.original || skill).pp -= pp
    end

    # Set the PP of a move
    # @param skill [Battle::Move]
    # @param pp [Integer]
    def set_pp(skill, pp)
      (skill.original || skill).pp = pp
    end

    # Set item on target
    # @param target [PFM::PokemonBattler]
    # @parma id [Integer]
    # @param overwrite_real [Boolean] if the real holding item should be overwritten
    def set_item(target, id, overwrite_real = false)
      return if @ignore || target.hp <= 0

      target.battle_item = id
      target.item_holding = id if overwrite_real
      change_spd(target, 1) if id == 0 && Abilities.has_ability_usable(target, 114) # Unburden
      log_error('Make sure set_item with Iron Ball work properly!')
      if id == 278 # Iron Ball (Should cancel levitate)
        if target.battle_effect.has_telekinesis_effect?
          msg(parse_text_with_pokemon(19, 1149, target))
          apply_effect(target, :apply_telekinesis, 0)
        end
      end
    end

    # Set a state on the battle engine
    # @param state [Symbol]
    # @param value [Object]
    def set_state(state, value)
      BattleEngine.state[state] = value.is_a?(PFM::PokemonBattler24) ? value.pokemon_battler : value
    end

    # Send a command to a state of the battle engine
    # @param state [Symbol]
    # @param cmd [Symbol]
    # @param args [Array]
    def send_state(state, cmd, *args)
      args = args.map { |i| i.is_a?(PFM::PokemonBattler24) ? i.pokemon_battler : i }
      BattleEngine.state[state].send(cmd, *args)
    end

    # Remove entry hazard
    # @param target [PFM::PokemonBattler]
    def entry_hazards_remove(target)
      if target.bank != 0
        BattleEngine._State_remove(:enn_spikes, 157)
        BattleEngine._State_remove(:enn_toxic_spikes, 161)
        BattleEngine._State_remove(:enn_stealth_rock, 165)
        BattleEngine._State_remove(:enn_sticky_web, 217)
      else
        BattleEngine._State_remove(:act_spikes, 156)
        BattleEngine._State_remove(:act_toxic_spikes, 160)
        BattleEngine._State_remove(:act_stealth_rock, 164)
        BattleEngine._State_remove(:act_sticky_web, 216)
      end
    end

    # Execute the morph effect
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    def morph(launcher, target)
      launcher.morph(target)
    end

    # Apply the out of reach effect to the target
    # @param target [PFM::PokemonBattler]
    # @param type [Integer]
    def apply_out_of_reach(target, type)
      apply_effect(target, :apply_out_of_reach, type)
    end

    # Force the HP of the target
    # @param target [PFM::PokemonBattler]
    # @param hp [Integer]
    def set_hp(target, hp)
      target.hp = hp
    end

    # Use a berry
    # @param target [PFM::PokemonBattler]
    # @param remove [Boolean] if the berry should be destroyed
    def berry_use(target, remove = false)
      animation_on(target, 496) # Change to the right animation
      imisc = GameData::Item[target.battle_item].misc_data
      if imisc && (berry = imisc.berry)
        target.edit_bonus(berry[:bonus])
      end
      if remove
        target.item_holding = target.battle_item = 0
      else
        target.battle_item_data << :berry
      end
    end

    # Use a berry in Pluck move
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    def berry_pluck(launcher, target)
      animation_on(target, 496) # Change to the right animation
      imisc = GameData::Item[target.battle_item].misc_data
      if imisc && (berry = imisc.berry)
        launcher.edit_bonus(berry[:bonus])
      end
      target.item_holding = target.battle_item = 0
    end

    # Effect of a berry curing the Pokemon
    # @param target [PFM::PokemonBattler]
    # @param item_name [String] name of the berry
    def berry_cure(target, item_name)
      return if @ignore || target.hp <= 0 || target.status == 0

      if target.poisoned? || target.toxic?
        id = 923
      elsif target.burn?
        id = 935
      elsif target.frozen?
        id = 932
      elsif target.paralyzed?
        id = 926
      else # asleep
        id = 929
      end
      target.cure
      status_bar_update(target)
      msg(parse_text_with_pokemon(19, id, target, ITEM2[1] => item_name))
    end

    # Cure confusion
    # @param target [PFM::PokemonBattler]
    # @param item_name [String] name of the berry
    def confuse_cure(target, item_name)
      return if @ignore || target.hp <= 0 || !target.confused?

      target.confuse = false
      msg(parse_text_with_pokemon(19, 938, target, ITEM2[1] => item_name))
    end

    # Cancel a move of the target
    # @param target [PFM::PokemonBattler]
    def cancel_attack(target)
      log_error('cancel_attack is not ready yet!')
      return
      @scene.actions.each do |i|
        if i[0] == 0 && i[3] == target
          i[0] = -1
        end
      end
    end

    # Move the action of the target after the current action
    # @param target [PFM::PokemonBattler]
    def after_you(target)
      log_error('after_you is not ready yet!')
      return
      actions = @scene.actions
      action = actions.find { |i| (i[0] == 0 && i[3] == target) }
      if(action)
        actions.delete(action)
        actions.insert(@scene.phase4_step + 1, action)
      end
    end

    # Move the target action at the end of the actions
    # @param target [PFM::PokemonBattler]
    def quash(target)
      log_error('quash is not ready yet!')
      return
      actions = @scene.actions
      action = actions.find { |i| (i[0] == 0 && i[3] == target) }
      if(action)
        actions.delete(action)
        actions.push(action)
      end
    end
  end
end
