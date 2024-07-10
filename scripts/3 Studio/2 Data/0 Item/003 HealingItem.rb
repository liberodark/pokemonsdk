module Studio
  # Data class describing an Item that is expected to heal a creature
  class HealingItem < Item
    # Get the loyalty malus
    # @return [Integer]
    attr_reader :loyalty_malus
  end
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::HealingItem) do |item, creature|
  next false if creature.egg?

  next (creature.dup.loyalty -= Studio::HealingItem.from(item).loyalty_malus) != creature.loyalty
end

PFM::ItemDescriptor.define_on_creature_use(Studio::HealingItem) do |item, creature|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::HealingItem) do |item, creature|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
end
