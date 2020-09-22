module BattleEngine
  class MessageInterpter
    private

    Status_Abilities = [12, 14, 21, 33, 65]
    Status_Items = [272, 273]
    Status_Not_Overwritten = [GameData::States::POISONED, GameData::States::BURN, GameData::States::PARALYZED, GameData::States::TOXIC]

    # Apply the Synchronize effect
    # @param target [PFM::PokemonBattler]
    # @param meth [Symbol] method to call in launcher
    def synchro_apply(target, meth)
      return if @ignore || target.hp <= 0

      if @launcher != target && @launcher && BattleEngine::Abilities.has_ability_usable(target, 33) # Synchronize
        return if Status_Not_Overwritten.include?(@launcher.status)

        @launcher.send(meth, true)
        msg(parse_text_with_pokemon(19, 1159, @launcher))
      elsif BattleEngine::Abilities.has_ability_usable(target, 80) # Quick Feet
        ability_display(target)
        change_spd(target, 1)
      end
    end

    # Confuse the target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean] if forced by a move
    # @param msg_id [Integer]
    def status_confuse(target, forced = false, msg_id = 345)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      if target.confused?
        msg(parse_text_with_pokemon(19, 354, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target && @skill
        msg_fail if @skill.power <= 0
        return
      end
      if !forced && be.has_safe_guard_effect?
        msg(parse_text_with_pokemon(19, 842, target))
        return
      end
      if BattleEngine::Abilities.has_ability_usable(target, 40)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 357, target))
        return
      end
      target.status_confuse
      msg(parse_text_with_pokemon(19, msg_id, target))
      status_bar_update(target)
    end

    # Put a target asleep
    # @param target [PFM::PokemonBattler]
    # @param nb_turn [Integer, nil]
    # @param msg_id [Integer]
    # @param forced [Boolean]
    def status_sleep(target, nb_turn = nil, msg_id = 306, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      # Herbivore
      if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
        ability_display(target)
        change_atk(target, 1)
        # msg(parse_text_with_pokemon(19, something_not_written,target))
        return
      end
      if target.asleep?
        msg(parse_text_with_pokemon(19, 315, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target
        msg_fail if @skill && @skill.power <= 0
        return
      end
      if !forced && be.has_safe_guard_effect?
        msg(parse_text_with_pokemon(19, 842, target))
        return
      end
      return if check_flora_voile(target, forced) == true

      if ($env.sunny? && BattleEngine::Abilities.has_ability_usable(target, 58)) || BattleEngine::Abilities.has_abilities(target, 30, 49)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 318, target))
        return
      end
      if target.can_be_asleep? || @skill&.id == 156
        target.status_sleep(true, nb_turn)
        target.status_count /= 2 if BattleEngine::Abilities.has_ability_usable(target, 41)
        msg(parse_text_with_pokemon(19, 306, target))
      else
        msg(parse_text_with_pokemon(19, 318, target))
      end

      status_bar_update(target)
    end

    # Freeze a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_frozen(target, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      # Herbivore
      if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
        ability_display(target)
        change_atk(target, 1)
        # msg(parse_text_with_pokemon(19, something_not_written,target))
        return
      end
      if target.frozen?
        msg(parse_text_with_pokemon(19, 297, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target
        msg_fail if @skill && @skill.power <= 0
        return
      end
      if !forced && be.has_safe_guard_effect?
        msg(parse_text_with_pokemon(19, 842, target))
        return
      end
      return if check_flora_voile(target, forced)

      if ($env.sunny? && BattleEngine::Abilities.has_ability_usable(target, 58)) || BattleEngine::Abilities.has_ability_usable(target, 82)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 300, target))
        return
      end

      if target.can_be_frozen?(@skill ? @skill.type : 0)
        target.status_frozen
        msg(parse_text_with_pokemon(19, 288, target))
      else
        msg(parse_text_with_pokemon(19, 300, target))
      end
      status_bar_update(target)
    end

    # Poison a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_poison(target, forced = false)
      return if @ignore or target.hp <= 0
      return if @no_secondary_effect

      if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
        ability_display(target)
        change_atk(target, 1)
        # msg(parse_text_with_pokemon(19, something_not_written,target))
        return
      end
      if target.poisoned?
        msg(parse_text_with_pokemon(19, 249, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target
        msg_fail if @skill && @skill.power <= 0
        return
      end
      if !forced && be.has_safe_guard_effect?
        msg(parse_text_with_pokemon(19, 842, target))
        return
      end
      return if check_flora_voile(target, forced) == true

      if ($env.sunny? && BattleEngine::Abilities.has_ability_usable(target, 58)) || BattleEngine::Abilities.has_ability_usable(target, 73)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 252, target))
        return
      end
      if target.can_be_poisoned?
        target.status_poison
        msg(parse_text_with_pokemon(19, 234, target))
        synchro_apply(target, :status_poison) if @launcher&.can_be_poisoned?
      else
        msg(parse_text_with_pokemon(19, 252, target))
      end
      status_bar_update(target)
    end

    # Intoxicate a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_toxic(target, forced = false)
      return if @ignore or target.hp <= 0
      return if @no_secondary_effect

      if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
        ability_display(target)
        change_atk(target, 1)
        # msg(parse_text_with_pokemon(19, something_not_written,target))
        return
      end
      if target.poisoned?
        msg(parse_text_with_pokemon(19, 249, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target
        msg_fail if @skill && @skill.power <= 0
        return
      end
      return if check_flora_voile(target, forced) == true

      if ($env.sunny? && BattleEngine::Abilities.has_ability_usable(target, 58)) || BattleEngine::Abilities.has_ability_usable(target, 73)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 252, target))
        return
      end
      if target.can_be_poisoned?
        target.status_toxic
        msg(parse_text_with_pokemon(19, 237, target))
        synchro_apply(target, :status_toxic) if @launcher&.can_be_poisoned?
      else
        msg(parse_text_with_pokemon(19, 252, target))
      end
      status_bar_update(target)
    end

    # Paralyze a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_paralyze(target, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      # Sap Sipper
      if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
        ability_display(target)
        change_atk(target, 1)
        # msg(parse_text_with_pokemon(19, something_not_written,target))
        return
      end
      if target.paralyzed?
        msg(parse_text_with_pokemon(19, 282, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target
        msg_fail if @skill && @skill.power <= 0
        return
      end
      if !forced && be.has_safe_guard_effect?
        msg(parse_text_with_pokemon(19, 842, target))
        return
      end
      return if check_flora_voile(target, forced) == true
      if ($env.sunny? && BattleEngine::Abilities.has_ability_usable(target, 58)) || BattleEngine::Abilities.has_ability_usable(target, 27)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 285, target))
        return
      end
      if target.can_be_paralyzed? || @skill&.id == 34
        target.status_paralyze
        msg(parse_text_with_pokemon(19, 273, target))
        synchro_apply(target, :status_paralyze) if @launcher&.can_be_paralyzed?
      else
        msg(parse_text_with_pokemon(19, 285, target))
      end
      status_bar_update(target)
    end

    # Burn a target
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def status_burn(target, forced = false)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect

      # Sap Sipper
      if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
        ability_display(target)
        change_atk(target, 1)
        # msg(parse_text_with_pokemon(19, something_not_written,target))
        return
      end
      if target.burn?
        msg(parse_text_with_pokemon(19, 267, target))
        return
      end
      be = target.battle_effect
      if be.has_substitute_effect? && @launcher != target
        msg_fail if @skill && @skill.power <= 0
        return
      end
      if !forced && be.has_safe_guard_effect?
        msg(parse_text_with_pokemon(19, 842, target))
        return
      end

      return if check_flora_voile(target, forced) == true

      if ($env.sunny? && BattleEngine::Abilities.has_ability_usable(target, 58)) || BattleEngine::Abilities.has_ability_usable(target, 62)
        ability_display(target)
        msg(parse_text_with_pokemon(19, 270, target))
        return
      end

      if target.can_be_burn?
        target.status_burn
        msg(parse_text_with_pokemon(19, 255, target))
        synchro_apply(target, :status_burn) if @launcher&.can_be_burn?
      else
        msg(parse_text_with_pokemon(19, 270, target))
      end
      status_bar_update(target)
    end

    # Check the Flower Veil
    # @param target [PFM::PokemonBattler]
    # @param forced [Boolean]
    def check_flora_voile(target, forced)
      if BattleEngine.get_ally(target)[0]
        c = BattleEngine.get_ally(target)[0]
      else
        c = target
      end

      if ((BattleEngine::Abilities.has_ability_usable(target, 165) && target.type_plante?) ||
         (BattleEngine::Abilities.has_ability_usable(c, 165) && target.type_plante?)) && (@skill&.id != 156)
        unless forced == true
          ability_display(target) unless c.ability == 165 && target.ability != 165
          ability_display(c) if c.ability == 165 && target.ability != 165
          msg(parse_text_with_pokemon(19, 1180, target))
          return true
        end
      end
    end

    # Heal the target
    # @param target [PFM::PokemonBattler]
    def status_cure(target)
      return if @ignore || target.hp <= 0
      return if target.status == 0

      if target.poisoned? || target.toxic?
        id = 246
      elsif target.burn?
        id = 264
      elsif target.frozen?
        id = 294
      elsif target.paralyzed?
        id = 279
      else # asleep
        id = 312
      end
      target.cure
      status_bar_update(target)
      msg(parse_text_with_pokemon(19, id, target))
    end

    # Force heal a frozen target
    # @param target [PFM::PokemonBattler]
    def ice_cure(target)
      return if @ignore || target.hp <= 0 || !target.frozen?

      target.cure
      msg(parse_text_with_pokemon(19, 294, target))
      status_bar_update(target)
    end

    # Force a status on the target
    # @param target [PFM::PokemonBattler]
    # @param status [Integer] ID of teh status
    def set_status(target, status)
      target.status = status
    end
  end
end
