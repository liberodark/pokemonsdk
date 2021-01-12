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
      @scene.display_message_and_wait(message, true) unless @no_more_msg
    end

    # Force display a message
    # @param message [String]
    def msgf(message)
      @scene.display_message_and_wait(message, true)
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
    def hp_down(target, hp, extra_info = 0)
      return if @ignore || target.hp <= 0

      @logic.damage_handler.damage_change_with_process(hp, target, @launcher, @skill)
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
      @scene.logic.weather_change_handler.weather_change_with_process(meteo_sym, nb_turn)
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
