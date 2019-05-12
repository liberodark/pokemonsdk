#encoding: utf-8

module PFM
  # List of Processes that are called when a skill is used in map
  # Associate a skill id to a proc that take 3 parameter : pkmn(PFM::Pokemon), skill(PFM::Skill), test(Array)
  SkillProcess = Hash.new
  SkillProcess[135] = SkillProcess[208] = proc do |pkmn, skill, *test|
    next :block if pkmn.hp == 0 and test.size > 0
    next :choice if test.size > 0 #Indiquer à la scène d'executer l'action en elle
    if($actors[$scene.return_data] != pkmn and !pkmn.dead? and pkmn.hp != pkmn.max_hp)
      #>Animation soin
      heal_hp = pkmn.max_hp*20/100
      $actors[$scene.return_data].hp -= heal_hp
      pkmn.hp += heal_hp
    else
      $scene.display_message($scene._parse(22, 108))
    end
  end
  SkillProcess[230] = proc do |pkmn, skill, *test| #Doux Parfum
    next false if test.size > 0 #Indique que la scène doit laisser les précédentes
    if $env.normal?
      if($wild_battle.available?)
        $game_system.map_interpreter.launch_common_event(1)
      else
        $scene.display_message(GameData::Text.get(39,7).clone)
      end
    else
      $scene.display_message(GameData::Text.get(39,8).clone)
    end
  end
  SkillProcess[19] = proc do |pkmn, skill, *test| #> Vol
    next false if test.size > 0 #Indique que la scène doit laisser les précédentes
    if $game_switches[Yuki::Sw::Env_CanFly]
      carte = GamePlay::WorldMap.new(:fly)
      carte.main
      Graphics.transition
      next true
    else
      next :block
    end
  end
end
