module Studio
  # Data class describing an Item that boost a specific stat of a creature in Battle
  class StatBoostItem < HealingItem
    # Get the symbol of the stat to boost
    # @return [Symbol]
    attr_reader :stat
    # Get the power of the stat to boost
    # @return [Integer]
    attr_reader :count
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::StatBoostItem) do
  next !$game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::StatBoostItem) do |item, creature|
  next false if creature.egg? || !PFM::PokemonBattler.from(creature).can_fight?

  next creature.send(:"#{item.stat}_stage") < 6
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::StatBoostItem) do |item, creature, scene|
  boost_item = Studio::StatBoostItem.from(item)
  creature.loyalty -= boost_item.loyalty_malus

  scene.logic.stat_change_handler.stat_change(boost_item.stat, boost_item.count, creature)
end

# Dire Hit
# Should be changed for Studio in the future
PFM::ItemDescriptor.define_chen_prevention(:dire_hit) do
  next !$game_temp.in_battle
end
PFM::ItemDescriptor.define_on_creature_usability(:dire_hit) do |_item, creature|
  next PFM::PokemonBattler.from(creature).can_fight?
end
PFM::ItemDescriptor.define_on_creature_battler_use(:dire_hit) do |_item, creature, scene|
  pokemon = PFM::PokemonBattler.from(creature)
  if %i[dragon_cheer focus_energy].any? { |e| pokemon.effects.has?(e) }
    scene.display_message_and_wait(text_get(18, 70))
    pokemon.bag.add_item(:dire_hit, 1)
  else
    pokemon.effects.add(Battle::Effects::FocusEnergy.new(scene.logic, pokemon))
    scene.display_message_and_wait(parse_text_with_pokemon(19, 1047, pokemon))
  end
end

# Guard Spec
# Should be changed for Studio in the future
PFM::ItemDescriptor.define_chen_prevention(:guard_spec) do
  next !$game_temp.in_battle
end
PFM::ItemDescriptor.define_on_creature_usability(:guard_spec) do |_item, creature|
  next PFM::PokemonBattler.from(creature).can_fight?
end
PFM::ItemDescriptor.define_on_creature_battler_use(:guard_spec) do |_item, creature, scene|
  pokemon = PFM::PokemonBattler.from(creature)
  if scene.logic.bank_effects[pokemon.bank].has?(:mist)
    scene.display_message_and_wait(text_get(18, 70))
    pokemon.bag.add_item(:guard_spec, 1)
  else
    scene.logic.bank_effects[pokemon.bank].add(Battle::Effects::Mist.new(scene.logic, pokemon.bank))
    scene.display_message_and_wait(parse_text(18, pokemon.bank == 0 ? 142 : 143))
  end
end
