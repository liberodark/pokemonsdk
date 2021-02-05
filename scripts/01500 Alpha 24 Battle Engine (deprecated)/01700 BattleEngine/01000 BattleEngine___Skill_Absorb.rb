#encoding: utf-8

#noyard

# Absorb related skills
module BattleEngine
  module_function

  # Dream Eater skill definition
  # @param launcher [PFM::Pokemon] user of the move
  # @param target [PFM::Pokemon] target of the move
  # @param skill [PFM::Skill] move that is currently used
  def s_dream_eater(launcher, target, skill, msg_push = true)
    return false unless __s_beg_step(launcher, target, skill, msg_push)

    unless target.asleep?
      _message_stack_push(MSG_Fail)
      return false
    end
    hp = _damage_calculation(launcher, target, skill).to_i
    return false if __s_hp_down_check(hp, target)

    if launcher.battle_effect.has_heal_block_effect?
      _message_stack_push([:msg, parse_text_with_pokemon(19, 890, launcher)])
      return
    end

    hp = 2 if hp < 2 #>Recover only 1 HP if the move dealt less than 2 HP of damage
    #>Verify the clone !
    _message_stack_push([:hp_up, launcher, hp / 2])
    _message_stack_push([:msg, parse_text_with_pokemon(19, 905, target)])

    __s_stat_us_step(launcher, target, skill)
    return true
  end
end
