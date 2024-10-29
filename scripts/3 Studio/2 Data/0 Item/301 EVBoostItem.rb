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

  if boost_item.count > 0
    missing_ev_amount =  [Configs.stats.max_stat_ev - creature.send(:"ev_#{boost_item.stat}"), Configs.stats.max_total_ev - creature.total_ev].min
  else
    missing_ev_amount = creature.send(:"ev_#{boost_item.stat}")
  end
  max_item_amount = missing_ev_amount / boost_item.count.abs
  max_item_amount += 1 if missing_ev_amount % boost_item.count != 0

  $game_temp.num_input_variable_id = Yuki::Var::EnteredNumber
  $game_temp.num_input_digits_max = $bag.item_quantity(item.db_symbol).to_s.size
  $game_temp.num_input_start = [$bag.item_quantity(item.db_symbol), max_item_amount].min
  PFM::Text.set_item_name(item.exact_name)
  scene.display_message(parse_text(22, 198))

  creature.loyalty -= boost_item.loyalty_malus * $game_variables[Yuki::Var::EnteredNumber]

  new_ev = (creature.send(:"ev_#{boost_item.stat}") + boost_item.count * $game_variables[Yuki::Var::EnteredNumber]).clamp(0, [Configs.stats.max_stat_ev, creature.send(:"ev_#{boost_item.stat}") + missing_ev_amount].min)
  creature.send(:"ev_#{boost_item.stat}=", new_ev)
  stat_name = text_get(22, Studio::EVBoostItem::STAT_NAME_TEXT_ID[boost_item.stat])
  message = parse_text(22, boost_item.count > 0 ? 118 : 136, PFM::Text::PKNICK[0] => creature.given_name, '[VAR EVSTAT(0001)]' => stat_name)
  scene.display_message_and_wait(message) unless $game_variables[Yuki::Var::EnteredNumber] == 0

  $bag.remove_item(item.db_symbol, $game_variables[Yuki::Var::EnteredNumber] - 1)
  PFM::Text.reset_variables
end
