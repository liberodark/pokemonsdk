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
  next false if creature.egg? || !PFM::PokemonBattler.from(creature).position

  next creature.send(:"#{item.stat}_stage") < 6
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::StatBoostItem) do |item, creature, scene|
  boost_item = Studio::StatBoostItem.from(item)
  creature.loyalty -= boost_item.loyalty_malus

  scene.logic.stat_change_handler.stat_change(boost_item.stat, boost_item.count, creature)
end
