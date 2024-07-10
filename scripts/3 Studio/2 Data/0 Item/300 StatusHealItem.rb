module Studio
  # Data class describing an Item that heals status
  class StatusHealItem < HealingItem
    # Get the list of states the item heals
    # @return [Array<Symbol>]
    attr_accessor :status_list

    # Get the status as Integer
    # @return [Array<Integer>]
    def status_id_list
      @status_id_list ||= status_list.map { |status| Configs.states.ids[status] }
    end
  end
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::StatusHealItem) do |item, creature|
  next false if creature.egg?

  status_heal_item = Studio::StatusHealItem.from(item)
  confuse_check = $game_temp.in_battle && creature.confused? && status_heal_item.status_list.include?(:confusion)
  next confuse_check || status_heal_item.status_id_list.include?(creature.status)
end

PFM::ItemDescriptor.define_on_creature_use(Studio::StatusHealItem) do |item, creature, scene|
  creature.loyalty -= Studio::StatusHealItem.from(item).loyalty_malus
  status = creature.status
  creature.status = 0
  message = parse_text(22, PFM::ItemDescriptor::BagStatesHeal[status], PFM::Text::PKNICK[0] => creature.given_name)
  scene.display_message_and_wait(message)
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::StatusHealItem) do |item, creature, scene|
  status_heal_item = Studio::StatusHealItem.from(item)
  creature.loyalty -= status_heal_item.loyalty_malus
  scene.logic.status_change_handler.status_change(:cure, creature) if status_heal_item.status_id_list.include?(creature.status)
  if status_heal_item.status_list.include?(:confusion) && creature.confused?
    scene.logic.status_change_handler.status_change(:confuse_cure, creature, message_overwrite: 351)
  end
end
