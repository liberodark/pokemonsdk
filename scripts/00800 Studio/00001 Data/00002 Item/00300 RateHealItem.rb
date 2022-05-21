module Studio
  # Data class describing an Item that heals a rate (0~100% using a number between 0 & 1) of hp
  class RateHealItem < HealingItem
    # Get the rate of hp this item can heal
    # @return [Float]
    attr_reader :hp_rate
  end
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::RateHealItem) do |_, creature|
  next false if creature.dead?

  next creature.hp < creature.max_hp
end

PFM::ItemDescriptor.define_on_creature_use(Studio::RateHealItem) do |item, creature, scene|
  original_hp = creature.hp
  creature.hp += (creature.max_hp * Studio::RateHealItem.from(item).hp_rate).to_i
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
  diff = creature.hp - original_hp
  message = parse_text(22, 109, PFM::Text::PKNICK[0] => creature.given_name, PFM::Text::NUM3[1] => diff.to_s)
  scene.display_message_and_wait(message)
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::RateHealItem) do |item, creature, scene|
  battle_item = Studio::RateHealItem.from(item)
  creature.loyalty -= battle_item.loyalty_malus
  scene.logic.damage_handler.heal(creature, (creature.max_hp * battle_item.hp_rate).to_i, test_heal_block: false)
end
