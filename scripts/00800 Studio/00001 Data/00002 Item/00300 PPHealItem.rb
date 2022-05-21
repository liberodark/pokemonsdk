module Studio
  # Data class describing an Item that heals a certain amount of PP of a single move
  class PPHealItem < HealingItem
    # Get the number of PP of the move that gets healed
    # @return [Integer]
    attr_reader :pp_count
  end
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::PPHealItem) do |_, creature|
  next false if creature.egg?

  moves = $game_temp.in_battle ? PFM::PokemonBattler.from(creature).moveset : creature.skills_set
  next moves.any? { |move| move.pp < move.ppmax }
end

PFM::ItemDescriptor.define_on_move_usability(Studio::PPHealItem, 34) do |_, skill|
  next skill.pp < skill.ppmax
end

PFM::ItemDescriptor.define_on_move_use(Studio::PPHealItem) do |item, creature, skill, scene|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus

  skill.pp += Studio::PPHealItem.from(item).pp_count
  scene.display_message_and_wait(parse_text(22, 114, PFM::Text::MOVE[0] => skill.name))
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::PPHealItem) do |item, creature, skill, scene|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus

  skill.pp += Studio::PPHealItem.from(item).pp_count
  scene.display_message_and_wait(parse_text(22, 114, PFM::Text::MOVE[0] => skill.name))
end
