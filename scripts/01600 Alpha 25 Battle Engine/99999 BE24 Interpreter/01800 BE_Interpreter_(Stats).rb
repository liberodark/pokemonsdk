module BattleEngine
  class MessageInterpter
    private

    # Position of text for Attack depending on the power
    TEXT_POS_ATK = [0, 27, 48, 69, 153, 174, 132, 111, 90]
    TEXT_POS_DFE = Array.new(9) { |i| TEXT_POS_ATK[i] + 3 }
    TEXT_POS_ATS = Array.new(9) { |i| TEXT_POS_ATK[i] + 6 }
    TEXT_POS_DFS = Array.new(9) { |i| TEXT_POS_ATK[i] + 9 }
    TEXT_POS_SPD = Array.new(9) { |i| TEXT_POS_ATK[i] + 12 }
    TEXT_POS_ACC = Array.new(9) { |i| TEXT_POS_ATK[i] + 15 }
    TEXT_POS_EVA = Array.new(9) { |i| TEXT_POS_ATK[i] + 18 }

    # Check if the stat chage is blocked by Flower Veil
    # @param target [PFM::PokemonBattler]
    def check_flora_stats(target)
      if BattleEngine.get_ally(target)[0]
        c = BattleEngine.get_ally(target)[0]
      else
        c = target
      end
      if (Abilities.has_abilities(target, 165) && target.type_grass?) || (Abilities.has_abilities(c, 165) && target.type_grass?)
        ability_display(target) unless c.ability == 165
        ability_display(c) if c.ability == 165
        msg(parse_text_with_pokemon(19, 198, target))
        return true
      end
      return false
    end

    # Get the new power modifier depending on the amount of stat changed
    # @param amount [Integer]
    # @param power [Integer]
    # @return [Integer]
    def stat_power_from_amount(amount, power)
      if amount != 0
        return (power < -2 ? -3 : (power > 2 ? 3 : power))
      else
        return (power > 0 ? 4 : 5)
      end
    end

    # Change the atk
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_atk(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        elsif Abilities.has_ability_usable(target, 51)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 201, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_atk(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 478 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_ATK[power], target))
    end

    # Change the dfe
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_dfe(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_dfe(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 480 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_DFE[power], target))
    end

    # Change the spd
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_spd(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_spd(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 482 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_SPD[power], target))
    end

    # Change the dfs
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_dfs(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_dfs(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 486 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_DFS[power], target))
    end

    # Change the ats
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_ats(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        # Herbivore
        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_ats(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 484 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_ATS[power], target))
    end

    # Change the eva
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_eva(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_eva(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 488 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_EVA[power], target))
    end

    # Change the acc
    # @param target [PFM::PokemonBattler]
    # @param power [Integer]
    def change_acc(target, power)
      return if @ignore || target.hp <= 0
      return if @no_secondary_effect
      return if target.battle_effect.has_no_stat_change_effect?
      return if target.battle_effect.has_substitute_effect? && @launcher != target && @skill && @skill.id != 432

      if power < 0 && target != @launcher
        return if check_flora_stats(target)

        if @skill&.type_grass? && BattleEngine::Abilities.has_ability_usable(target, 156)
          ability_display(target)
          change_atk(target, 1)
          # msg(parse_text_with_pokemon(19, something_not_written,target))
          return
        end
        if Abilities.has_abilities(target, 35, 101)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 198, target))
          return
        elsif Abilities.has_ability_usable(target, 7)
          ability_display(target)
          msg(parse_text_with_pokemon(19, 207, target))
          return
        end
      elsif power < 0
        if BattleEngine._has_item(target, 214)
          set_item(target, 0, 0)
          return
        end
      end
      power *= 2 if Abilities.has_ability_usable(target, 99)
      amount = target.change_acc(power)
      power = stat_power_from_amount(amount, power)
      animation_on(target, 490 + (power < 0 ? 1 : 0))
      msg(parse_text_with_pokemon(19, TEXT_POS_ACC[power], target))
    end
  end
end
