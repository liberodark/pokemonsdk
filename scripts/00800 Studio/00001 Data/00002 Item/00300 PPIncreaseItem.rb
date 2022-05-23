module Studio
  # Data class describing an Item that increase the PP of a move
  class PPIncreaseItem < HealingItem
    # Tell if this item sets the PP to the max possible amount
    # @return [Boolean]
    attr_reader :is_max
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::PPIncreaseItem) do
  next $game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::PPIncreaseItem) do |_, creature|
  next false if creature.egg?

  moves = $game_temp.in_battle ? PFM::PokemonBattler.from(creature).moveset : creature.skills_set
  next moves.any? { |move| (move.data.pp * 8 / 5) > move.ppmax }
end

PFM::ItemDescriptor.define_on_move_usability(Studio::PPIncreaseItem, 35) do |_, skill|
  next (skill.data.pp * 8 / 5) > skill.ppmax
end

PFM::ItemDescriptor.define_on_move_use(Studio::PPIncreaseItem) do |item, creature, skill, scene|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
  if Studio::PPIncreaseItem.from(item).is_max
    skill.ppmax = skill.data.pp * 8 / 5
  else
    skill.ppmax += skill.data.pp * 1 / 5
  end
  skill.pp += 99
  scene.display_message_and_wait(parse_text(22, 117, PFM::Text::MOVE[0] => skill.name))
end
