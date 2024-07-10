module Studio
  # Data class describing an Item that make creatures evolve
  class StoneItem < Item
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::StoneItem) do
  next $game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::StoneItem) do |item, creature|
  next false if creature.egg?

  next creature.evolve_check(:stone, item.db_symbol) && true # Party menu expect true, false or nil!
end

PFM::ItemDescriptor.define_on_creature_use(Studio::StoneItem) do |item, creature, scene|
  id, form = creature.evolve_check(:stone, item.db_symbol)
  GamePlay.make_pokemon_evolve(creature, id, form, true) do |evolve_scene|
    scene.running = false
    $bag.add_item(item.id, 1) unless evolve_scene.evolved
  end
end
