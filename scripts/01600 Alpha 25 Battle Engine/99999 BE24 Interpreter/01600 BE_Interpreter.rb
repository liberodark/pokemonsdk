module BattleEngine
  # Controller responcive of interpreting the messages of the Battle Engine
  class MessageInterpter
    # Replacement for the move in message
    MOVE_REP = '[VAR MOVE(0000)]'
    # List of be_method that describe multi hit moves
    MULTI_HIT_MOVES = %i[s_multi_hit s_2hits]
    # Create a new MessageInterpreter
    # @param scene [Battle::Scene]
    def initialize(scene)
      # @type [PFM::PokemonBattler]
      @launcher = nil
      # @type [PFM::PokemonBattler]
      @target = nil
      # Variable telling that we shouldn't display "x uses this"
      # @type [Boolean]
      @no_more_msg = false
      # @type [Battle::Move]
      @skill = nil
      # Tell to ignore some messages if the launcher or the target is KO
      # @type [Boolean]
      @ignore = false
      @skip_must_attack_effect = false
      @no_secondary_effect = false
      @ability_displayed = []
      @scene = scene
      @logic = scene.logic
      @visual = scene.visual
    end

    # Function that process the messages
    # @note replace PFM::PokemonBattler24 in the messages to PFM::PokemonBattler
    # @param stack [Array<Array>]
    def process_messages(stack)
      pb = PFM::PokemonBattler24
      stack.reverse_each do |message|
        message = message.map { |i| i.is_a?(pb) ? i.pokemon_battler : i }
        send(*message)
      end
    end

    private

    # Define the settings of the interpreter
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    def parametre(launcher, target, skill)
      @launcher = launcher
      @target = target
      @skill = skill.original || skill
      @ignore = (launcher.hp <= 0 || target.hp <= 0) if launcher && target
      @ignore = false if skill&.be_method == :s_explosion
      @no_secondary_effect = false
      target.battle_effect.last_attacking = launcher if skill && target && launcher != target
    end

    # Display a message
    # @param message [String]
    def msg(message)
      @scene.display_message(message, true) unless @no_more_msg
    end

    # Force display a message
    # @param message [String]
    def msgf(message)
      @scene.display_message(message, true)
    end

    # Update the hp bar of a Pokemon
    # @param pokemon [PFM::PokemonBattler]
    def refresh_bar(pokemon)
      @visual.refresh_info_bar(pokemon)
    end

    # Display the message of failure
    # @param target [PFM::PokemonBattler, nil]
    def msg_fail(target = nil)
      if target
        msg(parse_text_with_pokemon(19, 24, target))
      else
        msg(parse_text(18, 74))
      end
      BattleEngine.state[:last_skill] = nil
    end

    # Tell the interpreter to stop showing messages
    def no_more_msg
      @no_more_msg = true
    end

    # Show a critical hit message
    def critical_hit
      msg(parse_text(18, 84)) unless @ignore
    end

    # Show the usage of the move
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    def use_skill_msg(launcher, target, skill)
      return if @ignore || target.hp <= 0
=begin
      msg(parse_text_with_pokemon(8999 - GameData::Text::CSV_BASE, 12, launcher,
                                  PKNAME[0] => launcher.given_name,
                                  MOVE_REP => skill.name))
      @scene.animation(launcher, target, skill)
=end
    end

    # Show the move is efficient message
    def efficient_msg
      return if @ignore

      msg(parse_text(18, 81))

      hp_up(@target, 10, 914, ITEM2[1] => @target.item_name) if BattleEngine._has_item(@target, 208) # Enigma berry
      if BattleEngine._has_item(@target, 639) # Weakness Policy
        set_item(@target, 0, true)
        change_atk(@target, 2)
        change_ats(@target, 2)
      end
    end

    # Show the this move is not really efficient message
    def unefficient_msg
      msg(parse_text(18, 82)) unless @ignore
    end

    # Show the this move has no effect message
    def useless_msg(target)
      msg(parse_text_with_pokemon(19, 210, target)) unless @ignore || target.hp <= 0
    end

    # Play the efficiency sound
    def efficiency_sound(mod)
      return if @ignore or mod == 0

      if mod == 1
        Audio.se_play('Audio/SE/hit.wav')
      elsif mod > 1
        Audio.se_play('Audio/SE/hitplus.wav')
      else
        Audio.se_play('Audio/SE/hitlow.wav')
      end
    end

    # Show the failure message
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    def launcher_fail_msg(launcher, target)
      msg(parse_text_with_pokemon(19, 24, target)) unless @ignore || target.hp <= 0
    end

    # Show the evasion message
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    def target_evasion_msg(launcher, target)
      msg(parse_text_with_pokemon(19, 213, target)) unless @ignore || target.hp <= 0
    end

    # Perform the HP Down sequence
    # @param target [PFM::PokemonBattler]
    # @param hp [Integer]
    # @param extra_info [Integer]
    def hp_down(target, hp, extra_info=0)
      return if @ignore || target.hp <= 0
      @target = target

      be = target.battle_effect
      #> Substitute check
      if(@skill && !@skill.sound_attack? && be.has_substitute_effect?)
        sub_hp = be.substitute_hp
        be.substitute_hp -= hp
        hp -= sub_hp
        if(hp > 0)
          msg(parse_text_with_pokemon(19, 794, target))
          switch_form(target)
        else
          msg(parse_text_with_pokemon(19, 791, target))
          be.last_damaging_skill = nil
          return
        end
      end
      #> Endure & Focus Band checks
      if hp >= target.hp && @skill
        if be.has_endure_effect? || (BattleEngine._has_item(target, 230) && rand(10) == 0)
          hp = target.hp - 1
        elsif BattleEngine._has_item(target, 275)
          if target.hp == target.max_hp && !MULTI_HIT_MOVES.include?(@skill.symbol)
            hp = target.hp - 1
            set_item(target, 0, true)
          end
        end
      end
      #> If the Pokémon has abilities that prevent it from losing HP
      return unless Abilities.before_damage_ability(target, @skill, hp)

      hp_down_proto(target, hp)
      #> Check berries & Gluttony
      if BattleEngine._has_item(target, target.battle_item)
        item_id = target.battle_item
        gl_rate = Abilities.has_ability_usable(target, 81) ? 2 : 1 #> Gluttony
        if((target.hp_rate*3) <= 2)
          if item_id == 155 #> Baie Oran
            berry_use(target)
            hp_up(target, 10, 914, ITEM2[1] => target.item_name)
          elsif item_id == 158 #> Baie Citrus
            berry_use(target)
            hp_up(target, target.max_hp/4, 914, ITEM2[1] => target.item_name)
          end
        end
        if((target.hp_rate*4) <= gl_rate) #> Augmentations de stat
          if(item_id == 206) #> Baie Lensa
            berry_use(target)
            target.critical_rate += 1
          elsif(item_id == 207) #> Baie Frista
            berry_use(target)
            send(PFM::ItemDescriptor::Boost[rand(6)], target, 1)
          elsif(item_id == 210) #> Baie Chérim
            berry_use(target)
            target.battle_item_data << :attack_first
          elsif((heal_data = ::GameData::Item[item_id].heal_data) && heal_data.battle_boost)
            berry_use(target)
            send(PFM::ItemDescriptor::Boost[heal_data.battle_boost], target, 1)
          end
        elsif((target.hp_rate*8) <= 7) #> Soin de 1/8
          if(item_id <= 163 && item_id >= 159)
            berry_use(target)
            hp_up(target, target.max_hp/8, 920, ITEM2[1] => target.item_name)
            #!!!Confusion !!!
          end
        end
        #> Ballon
        if(item_id == 541 && BattleEngine.state[:gravity] <= 0)
          msg(parse_text_with_pokemon(19, 411, target))
          set_item(target, 0, true)
        end
        if(@skill)
          if((@skill.physical? && item_id == 211) || 
            (@skill.special? && item_id == 212)) #> Baie Jaboca / Baie Pommo
            berry_use(target)
            hp_down_proto(@launcher, @launcher.max_hp/8)
            msg(parse_text_with_pokemon(19, 1044, @launcher, ITEM2[1] => target.item_name))
          elsif(@skill.physical? && item_id == 687) #> Baie Éka
            berry_use(target)
            send(PFM::ItemDescriptor::Boost[4], target, 1)
          elsif(@skill.special? && item_id == 688) #> Baie Rangma
            berry_use(target)
            send(PFM::ItemDescriptor::Boost[1], target, 1)
          elsif(@skill.type_water? && item_id == 648) #> Lichen Lumineux
            change_dfs(target, 1)
            set_item(target, 0, true)
          elsif(@skill.type_ice? && item_id == 649) #> Boule neige
            change_atk(target, 1)
            set_item(target, 0, true)
          end
        end
      end
      #> Update of taken damages
      if @skill
        be.take_damages(hp, @skill.atk_class, @launcher)
        be.last_damaging_skill = @skill
        #> Destiny Bond
        if(target.last_skill == 194 && @launcher && @launcher != target && target.hp <= 0)
          hp_down(@launcher, @launcher.hp, true)
          msg(parse_text_with_pokemon(19, 629, target))
        end
        #> Rage
        change_atk(target,1) if be.has_rage_effect?
        #> Grudge
        if(be.has_grudge_effect? && target.dead?)
          pp_down(@launcher, @skill, @skill.pp)
          msg(parse_text_with_pokemon(19, 635, @launcher, MOVE[1] => @skill.name))
        end
        #> Shell Bell
        if BattleEngine._has_item(@launcher, 253)
          hp_up(@launcher, hp / 8) if hp > 7
        #> Sticky Barb
        elsif(BattleEngine::_has_item(target, 288))
          hp_down_proto(@launcher, @launcher.max_hp / 8)
          if(@launcher.battle_item == 0)
            set_item(@launcher, 288)
            set_item(target, 0)
          end
        #> Roche Royale
        elsif(@skill.king_rock_utility && BattleEngine::_has_item(target, 221) && rand(10) == 0)
          effect_afraid(@launcher)
        #> Croc Rasoir
        elsif(BattleEngine::_has_item(target, 327) && rand(10) == 0)
          effect_afraid(target)
        end
        Abilities.on_dammage_ability(@launcher, target, @skill)
        if(target.battle_item_data.include?(:berry))
          target.item_holding = 0 if target.battle_item == target.item_holding
          target.battle_item = 0
        end
      end
    end

    # Function that lower the HP of the target
    # @param target [PFM::PokemonBattler]
    # @param hp [Integer]
    def hp_down_proto(target, hp)
      return if @ignore || target.hp <= 0

      @visual.show_hp_animations([target], [-hp])
    end

    # Function that increase the HP of the target
    # @param target [PFM::PokemonBattler]
    # @param hp [Integer]
    def hp_up(target, hp, msg = nil, *args)
      return if @ignore || target.hp <= 0

      msg(parse_text_with_pokemon(19, msg, target, *args)) if msg
      @visual.show_hp_animations([target], [hp])
    end

    # Function that show OHKO / Sacrifices
    # @param target [PFM::PokemonBattler]
    # @param sacrifice [Boolean] if the move was a sacrifice
    def OHKO(target, sacrifice = false)
      return if @ignore || target.hp <= 0

      #> Sturdy
      if Abilities.has_ability_usable(target, 37)
        ability_display(target)
        msg_fail
        return
      end
      hp_down_proto(target, target.hp)
      #> Destiny Bond
      if(!sacrifice && target.last_skill == 194 && @launcher && @launcher != target)
        hp_down(@launcher, @launcher.hp, true)
        msg(parse_text_with_pokemon(19, 629, target))
      end
      Abilities.on_dammage_ability(@launcher, target, @skill) if @skill
    end

    # Display an animation
    # @param id [Integer]
    def animation(id)
      #print "Affichage de l'animation #{message[1]}"
    end

    # End the battle with flee
    def end_flee
      $game_system.se_play($data_system.escape_se)
      @scene.battle_end(1)
    end

    # Change the form of a Pokemon
    # @param target [PFM::PokemonBattler]
    def switch_form(target)
      log_error('Switch form is not implemented yet!!!')
      # @scene.gr_switch_form(target)
    end

    # Change the weather
    # @param meteo_sym [Symbol] kind of weather (:rain, :sunny, :sandstorm, :heil, :fog, :none)
    # @param nb_turn [Integer] Number of turn the weather will be applied
    def weather_change(meteo_sym, nb_turn = 5)
      case meteo_sym
      when :rain
        $env.apply_weather(1, nb_turn)
        msg(parse_text_with_pokemon(18, 88, nil))
      when :sunny
        $env.apply_weather(2, nb_turn)
        msg(parse_text_with_pokemon(18, 87, nil))
      when :sandstorm
        $env.apply_weather(3, nb_turn)
        msg(parse_text_with_pokemon(18, 89, nil))
      when :hail
        $env.apply_weather(4, nb_turn)
        msg(parse_text_with_pokemon(18, 90, nil))
      when :fog
        $env.apply_weather(5, nb_turn)
        msg(parse_text_with_pokemon(18, 91, nil))
      else
        $env.apply_weather(0, nb_turn)
      end
      #> Display that the effect will not work
      if($env.current_weather != 0 && BattleEngine.state[:air_lock])
        ability_display(BattleEngine.state[:air_lock])
        @scene.display_message(parse_text(18, 97)) # "The effects of the weather disappeared."
      end
      #> Weather ability
      Abilities.on_weather_change
    end

    # Display an ability
    # @param target [PFM::PokemonBattler]
    # @param display_condition [#call] specific condition returning a boolean telling if the ability should be shown or not
    def ability_display(target, display_condition = nil)
      if display_condition
        return unless display_condition.call
      end
      # Prevent intenpestive display
      return if @ability_displayed.include?(target) && @ability_displayed[-1] == target

      log_error('ability_display is not ready yet!')
      # @scene.ability_display(target)
      @ability_displayed << target
    end

    # Function that update the Info Box of a Pokemon
    # @param pokemon [PFM::PokemonBattler]
    def status_bar_update(pokemon)
      @visual.refresh_info_bar(pokemon)
    end

    # Show the stat mod message
    def stat_mod_or_unk(message)
      log_error("Unkown stat modificator : #{message[0]}")
    end

    # Show an animation
    # @param id [Integer] ID of the animation
    def global_animation(id)
      @visual.show_rmxp_animation(@launcher || @target || @logic.battler(0, 0), id)
    end

    # Show an animation on a target
    # @param target [PFM::PokemonBattler]
    # @param id [Integer] ID of the animation
    def animation_on(target, id)
      return if @ignore

      @visual.show_rmxp_animation(target, id)
    end

    # Show extra skill animation
    # @param launcher [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @param skill [Battle::Move]
    def skill_animation(launcher, target, skill)
      return if @ignore

      @visual.show_move_animation(launcher, [target], skill)
    end
  end
end
