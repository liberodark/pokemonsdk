module Studio
  # Data class describing an Item that boost an EV stat of a Pokemon
  class EVBoostItem < StatBoostItem
    # List of text ID to get the stat name
    STAT_NAME_TEXT_ID = {
      hp: 134,
      atk: 129,
      dfe: 130,
      spd: 133,
      ats: 131,
      dfs: 132
    }
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::EVBoostItem) do
  next $game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::EVBoostItem) do |item, creature|
  next false if creature.egg?

  ev_boost = Studio::EVBoostItem.from(item)
  next false if creature.total_ev >= Configs.stats.max_total_ev && ev_boost.count > 0
  
  next creature.send(:"ev_#{ev_boost.stat}") < Configs.stats.max_stat_ev if ev_boost.count > 0
  next creature.send(:"ev_#{ev_boost.stat}") > 0 if ev_boost.count < 0
end

PFM::ItemDescriptor.define_on_creature_use(Studio::EVBoostItem) do |item, creature, scene|
  boost_item = Studio::EVBoostItem.from(item)
  creature.loyalty -= boost_item.loyalty_malus
  new_ev = (creature.send(:"ev_#{boost_item.stat}") + boost_item.count).clamp(0, Configs.stats.max_stat_ev)
  creature.send(:"ev_#{boost_item.stat}=", new_ev)
  stat_name = text_get(22, Studio::EVBoostItem::STAT_NAME_TEXT_ID[boost_item.stat])
  message = parse_text(22, boost_item.count > 0 ? 118 : 136, PFM::Text::PKNICK[0] => creature.given_name, '[VAR EVSTAT(0001)]' => stat_name)
  scene.display_message_and_wait(message)
end
