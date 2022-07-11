module Studio
  # Data class describing an Item that heals a constant amount of hp and heals status as well
  class StatusConstantHealItem < ConstantHealItem
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

PFM::ItemDescriptor.define_on_creature_usability(Studio::StatusConstantHealItem) do |item, creature|
  next false if creature.egg?

  heal_item = Studio::StatusConstantHealItem.from(item)
  states = heal_item.status_list
  include_death = states.include?(:death)
  next false if creature.dead? && !include_death
  next false if creature.alive? && include_death
  next false if $game_temp.in_battle && creature.dead? && include_death && PFM.game_state.nuzlocke.enabled?

  confuse_check = $game_temp.in_battle && creature.confused? && states.include?(:confusion)
  next creature.hp < creature.max_hp || confuse_check || heal_item.status_id_list.include?(creature.status)
end

PFM::ItemDescriptor.define_on_creature_use(Studio::StatusConstantHealItem) do |item, creature, scene|
  original_hp = creature.hp
  heal_item = Studio::StatusConstantHealItem.from(item)
  creature.hp += heal_item.hp_count
  creature.loyalty -= heal_item.loyalty_malus
  diff = creature.hp - original_hp
  if diff != 0
    message = parse_text(22, 109, PFM::Text::PKNICK[0] => creature.given_name, PFM::Text::NUM3[1] => diff.to_s)
    scene.display_message_and_wait(message)
  end
  status = creature.status
  if status != 0 && heal_item.status_id_list.include?(status)
    creature.status = 0
    message = parse_text(22, PFM::ItemDescriptor::BagStatesHeal[status], PFM::Text::PKNICK[0] => creature.given_name)
    scene.display_message_and_wait(message)
  end
end

PFM::ItemDescriptor.define_on_creature_battler_use(Studio::StatusConstantHealItem) do |item, creature, scene|
  battle_item = Studio::StatusConstantHealItem.from(item)
  creature.loyalty -= battle_item.loyalty_malus
  was_dead = creature.dead?
  scene.logic.damage_handler.heal(creature, battle_item.hp_count, test_heal_block: false)
  if was_dead && creature.position >= 0 && creature.position < scene.battle_info.vs_type
    scene.visual.battler_sprite(creature.bank, creature.position).go_in
    scene.visual.show_info_bar(creature)
  end
  scene.logic.status_change_handler.status_change(:cure, creature) if battle_item.status_id_list.include?(creature.status)
  if battle_item.status_list.include?(:confusion) && creature.confused?
    scene.logic.status_change_handler.status_change(:confuse_cure, creature, message_overwrite: 351)
  end
end
