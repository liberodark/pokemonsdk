#encoding: utf-8

#noyard
module BattleEngine
  module BE_Interpreter
    module_function
    #===
    #>Synchro
    #===
    def synchro_apply(target, meth)
      return if @ignore or target.hp==0
      #> Synchro
      if(@launcher != target and @launcher and BattleEngine::Abilities.has_ability_usable(target, 33))
        @launcher.send(meth, true)
        _msgp(19, 1159, @launcher)
      #> Pied Véloce
      elsif(BattleEngine::Abilities.has_ability_usable(target, 80))
        _mp([:ability_display, target])
        _mp([:change_spd, target, 1])
      end
    end
    #===
    #>Rendre confus
    #  Forced indique une confusion auto induite ou provenant d'une cap' (colère etc...)
    #===
    def status_confuse(target, forced=false, msg_id = 345)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà confus
      if(target.confused?)
        _msgp(19, 354, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Rune protect
      if(!forced and be.has_safe_guard_effect?)
        _msgp(19, 842, target)
        return
      end
      #> Tempo perso
      if(BattleEngine::Abilities.has_ability_usable(target, 40))
        _mp([:ability_display, target])
        _msgp(19, 357, target)
        return
      end
      #> Rendre finalement confus
      target.status_confuse
      _msgp(19, msg_id, target)
      @scene.status_bar_update(target)
    end
    #===
    #>Endormir
    #===
    def status_sleep(target, nb_turn = nil, msg_id = 306, forced = false)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà endormi
      if(target.asleep?)
        _msgp(19, 315, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Rune protect
      if(!forced and be.has_safe_guard_effect?)
        _msgp(19, 842, target)
        return
      end
      #> Feuille Garde / Esprit Vital / Insomnia
      if(($env.sunny? and BattleEngine::Abilities.has_ability_usable(target, 58)) or
        BattleEngine::Abilities.has_abilities(target, 30, 49))
        _mp([:ability_display, target])
        _msgp(19, 318, target)
        return
      end
      #> On endort le Pokémon
      if(target.can_be_asleep? or (@skill and @skill.id == 156)) #> Repos
        target.status_sleep(true, nb_turn)
        #> Matinal
        if(BattleEngine::Abilities.has_ability_usable(target, 41))
          target.status_count /= 2
        end
        _msgp(19, 306, target)
        synchro_apply(target, :status_sleep)
      else
        _msgp(19, 318, target)
      end
      @scene.status_bar_update(target)
    end
    #===
    #>Geler
    #===
    def status_frozen(target, forced = false)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà gelé
      if(target.frozen?)
        _msgp(19, 297, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Rune protect
      if(!forced and be.has_safe_guard_effect?)
        _msgp(19, 842, target)
        return
      end
      #> Feuille Garde / Armumagma
      if(($env.sunny? and BattleEngine::Abilities.has_ability_usable(target, 58)) or
        BattleEngine::Abilities.has_ability_usable(target, 82))
        _mp([:ability_display, target])
        _msgp(19, 300, target)
        return
      end
      #> Geler la cible
      if target.can_be_frozen?(@skill ? @skill.type : 0)
        target.status_frozen
        _msgp(19, 288, target)
        synchro_apply(target, :status_frozen)
      else
        _msgp(19, 300, target)
      end
      @scene.status_bar_update(target)
    end
    #===
    #>Enpoisonner
    #===
    def status_poison(target, forced = false)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà empoisonné
      if(target.poisoned?)
        _msgp(19, 249, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Rune protect
      if(!forced and be.has_safe_guard_effect?)
        _msgp(19, 842, target)
        return
      end
      #> Feuille Garde / Vaccin
      if(($env.sunny? and BattleEngine::Abilities.has_ability_usable(target, 58)) or
        BattleEngine::Abilities.has_ability_usable(target, 73))
        _mp([:ability_display, target])
        _msgp(19, 252, target)
        return
      end
      #> Empoisonner
      if target.can_be_poisoned?
        target.status_poison
        _msgp(19, 234, target)
        synchro_apply(target, :status_poison)
      else
        _msgp(19, 252, target)
      end
      @scene.status_bar_update(target)
    end
    #===
    #>Intoxiquer
    #===
    def status_toxic(target, forced = false)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà empoisonné
      if(target.poisoned?)
        _msgp(19, 249, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Feuille Garde / Vaccin
      if(($env.sunny? and BattleEngine::Abilities.has_ability_usable(target, 58)) or
        BattleEngine::Abilities.has_ability_usable(target, 73))
        _mp([:ability_display, target])
        _msgp(19, 252, target)
        return
      end
      #> Intoxiquer
      if target.can_be_poisoned?
        target.status_toxic
        _msgp(19, 237, target)
        synchro_apply(target, :status_toxic)
      else
        _msgp(19, 252, target)
      end
      @scene.status_bar_update(target)
    end
    #===
    #>Paralyser
    #===
    def status_paralyze(target, forced = false)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà Paralysé
      if(target.paralyzed?)
        _msgp(19, 282, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Rune protect
      if(!forced and be.has_safe_guard_effect?)
        _msgp(19, 842, target)
        return
      end
      #> Feuille Garde / Echauffement
      if(($env.sunny? and BattleEngine::Abilities.has_ability_usable(target, 58)) or
        BattleEngine::Abilities.has_ability_usable(target, 27))
        _mp([:ability_display, target])
        _msgp(19, 285, target)
        return
      end
      #> Paralyser
      if target.can_be_paralyzed? or (@skill and @skill.id == 34) #> Plaquage
        target.status_paralyze
        _msgp(19, 273, target)
        synchro_apply(target, :status_paralyze)
      else
        _msgp(19, 285, target)
      end
      @scene.status_bar_update(target)
    end
    #===
    #>Brûler
    #===
    def status_burn(target, forced = false)
      return if @ignore or target.hp==0
      return if @no_secondary_effect
      #> Déjà brûlé
      if(target.burn?)
        _msgp(19, 267, target)
        return
      end
      be = target.battle_effect
      #> Clonage
      if(be.has_substitute_effect? and @launcher != target and @skill)
        msg_fail if @skill.power <= 0
        return
      end
      #> Rune protect
      if(!forced and be.has_safe_guard_effect?)
        _msgp(19, 842, target)
        return
      end
      #> Feuille Garde / Ignifu-Voile
      if(($env.sunny? and BattleEngine::Abilities.has_ability_usable(target, 58)) or
        BattleEngine::Abilities.has_ability_usable(target, 62))
        _mp([:ability_display, target])
        _msgp(19, 270, target)
        return
      end
      #> Brûler
      if target.can_be_burn?
        target.status_burn
        _msgp(19, 255, target)
        synchro_apply(target, :status_burn)
      else
        _msgp(19, 270, target)
      end
      @scene.status_bar_update(target)
    end
    #===
    #>Soigner la cible
    #===
    def status_cure(target)
      return if @ignore or target.hp==0
      if(target.status==0)
#        @scene.display_message(GameData.b_str(47, target.given_name)) #"N'a aucune altération de status, cela échoue.")
        return
      end
      if(target.poisoned? or target.toxic?)
        id = 246
      elsif(target.burn?)
        id = 264
      elsif(target.frozen?)
        id = 294
      elsif(target.paralyzed?)
        id = 279
      else #asleep
        id = 312
      end
      target.cure
      @scene.status_bar_update(target)
      _msgp(19, id, target)
    end
    #===
    #>Soin forcé du gel
    #===
    def ice_cure(target)
      return if @ignore or target.hp==0 or !target.frozen?
      target.cure
      _msgp(19, 294, target)
      @scene.status_bar_update(target)
    end
    #===
    #> Forcer un statut
    #===
    def set_status(target, status)
      target.status = status
    end
  end
end
