module GameData
  # Item that heals a constant amount of hp and heals status as well
  class StatusConstantHealItem < ConstantHealItem
    # Get the list of states the item heals
    # @return [Array<Integer>]
    attr_accessor :status_list
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param hp_count [Integer] number of hp it heals
    # @param status_list [Array<Integer>]
    def initialize(*initialize_params, loyalty_malus, hp_count, status_list)
      super(*initialize_params, loyalty_malus, hp_count)
      @status_list = status_list
    end
  end
end

safe_code('Define StatusConstantHealItem ItemDescriptor') do
  PFM::ItemDescriptor.define_on_pokemon_usability(GameData::StatusConstantHealItem) do |_, pokemon|
    next false if pokemon.dead?

    states = GameData::StatusConstantHealItem.from(item).status_list
    next pokemon.hp < pokemon.max_hp || (pokemon.confused? && states.include?(GameData::States::CONFUSED)) || states.include?(pokemon.status)
  end

  PFM::ItemDescriptor.define_on_pokemon_use(GameData::StatusConstantHealItem) do |item, pokemon, scene|
    original_hp = pokemon.hp
    pokemon.hp += GameData::ConstantHealItem.from(item).hp_count
    pokemon.loyalty -= GameData::HealingItem.from(item).loyalty_malus
    diff = pokemon.hp - original_hp
    if diff != 0
      message = parse_text(22, 109, PFM::Text::PKNICK[0] => pokemon.given_name, PFM::Text::NUM3[1] => diff.to_s)
      scene.display_message_and_wait(message)
    end
    status = pokemon.status
    if status != 0
      pokemon.status = 0
      message = parse_text(22, PFM::ItemDescriptor::BagStatesHeal[status], PFM::Text::PKNICK[0] => pokemon.given_name)
      scene.display_message_and_wait(message)
    end
  end

  PFM::ItemDescriptor.define_on_pokemon_battler_use(GameData::StatusConstantHealItem) do |item, pokemon, scene|
    battle_item = GameData::StatusConstantHealItem.from(item)
    pokemon.loyalty -= battle_item.loyalty_malus
    scene.display_message_and_wait(parse_text_with_pokemon(19, 387, pokemon))
    scene.logic.damage_handler.damage_change(-battle_item.hp_count, pokemon)
    states = battle_item.status_list
    scene.logic.status_change_handler.status_change(:cure, pokemon) if states.include?(pokemon.status)
    if states.include?(GameData::States::CONFUSED) && pokemon.confused?
      scene.logic.status_change_handler.status_change(:confuse_cure, pokemon, message_overwrite: 351)
    end
  end
end
