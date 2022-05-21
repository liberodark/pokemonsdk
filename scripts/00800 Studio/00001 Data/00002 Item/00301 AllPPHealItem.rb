module Studio
  # Data class describing an Item that heals a certain amount of PP of all moves
  class AllPPHealItem < PPHealItem
  end
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::AllPPHealItem) do |_, creature|
  next false if creature.egg?

  moves = $game_temp.in_battle ? PFM::PokemonBattler.from(creature).moveset : creature.skills_set
  next moves.any? { |move| move.pp < move.ppmax }
end

PFM::ItemDescriptor.define_on_creature_use(Studio::AllPPHealItem) do |item, creature, scene|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
  pp_count = Studio::AllPPHealItem.from(item).pp_count

  creature.skills_set.each { |skill| skill.pp += pp_count }
  scene.display_message_and_wait(parse_text(22, 114, PFM::Text::PKNICK[0] => creature.given_name))
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::AllPPHealItem) do |item, creature, scene|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
  pp_count = Studio::AllPPHealItem.from(item).pp_count

  creature.moveset.each { |move| move.pp += pp_count }
  scene.display_message_and_wait(parse_text(22, 114, PFM::Text::PKNICK[0] => creature.given_name))
end
