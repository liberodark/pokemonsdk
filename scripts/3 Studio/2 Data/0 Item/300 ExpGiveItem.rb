module Studio
  # Data class describing an Item that gives the level of the Pokemon
  class ExpGiveItem < HealingItem
    # Get the number of exp point this item gives
    # @return [Integer]
    attr_reader :exp_count
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::ExpGiveItem) do
  next $game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::ExpGiveItem) do |_item, creature|
  next false if creature.egg?

  # Unlike Rare Candies, we can only use it if the creature isn't already at the max level
  next (creature.level + 1) < creature.max_level
end

PFM::ItemDescriptor.define_on_creature_use(Studio::ExpGiveItem) do |item, creature, scene|
  exp_count = Studio::ExpGiveItem.from(item).exp_count
  index = $actors.find_index(creature)
  # TODO: Rework this code later to patch in the ExpDistribution global UI (https://app.clickup.com/t/86bzu5w2y)
  $game_system.map_interpreter.give_exp(index, exp_count)
end
