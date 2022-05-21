module Studio
  # Data class describing an Item that heals a constant amount of hp
  class ConstantHealItem < HealingItem
    # Get the number of hp the item heals
    # @return [Integer]
    attr_reader :hp_count
  end
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::ConstantHealItem) do |_, creature|
  next false if creature.dead?

  next creature.hp < creature.max_hp
end

PFM::ItemDescriptor.define_on_creature_use(Studio::ConstantHealItem) do |item, creature, scene|
  original_hp = creature.hp
  creature.hp += Studio::ConstantHealItem.from(item).hp_count
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
  diff = creature.hp - original_hp
  message = parse_text(22, 109, PFM::Text::PKNICK[0] => creature.given_name, PFM::Text::NUM3[1] => diff.to_s)
  scene.display_message_and_wait(message)
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::ConstantHealItem) do |item, creature, scene|
  battle_item = Studio::ConstantHealItem.from(item)
  creature.loyalty -= battle_item.loyalty_malus
  scene.logic.damage_handler.heal(creature, battle_item.hp_count, test_heal_block: false)
end
