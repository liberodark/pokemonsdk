module Studio
  # Data class describing an Item that gives experience to a Pokemon
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
  next creature.level < creature.max_level
end

PFM::ItemDescriptor.define_on_creature_use(Studio::ExpGiveItem) do |item, creature, scene|
  missing_exp_total = creature.exp_list[creature.max_level] - creature.exp
  max_candy_amount = missing_exp_total / Studio::ExpGiveItem.from(item).exp_count
  max_candy_amount += 1 if missing_exp_total % Studio::ExpGiveItem.from(item).exp_count != 0

  $game_temp.num_input_variable_id = Yuki::Var::EnteredNumber
  $game_temp.num_input_digits_max = $bag.item_quantity(item.db_symbol).to_s.size
  $game_temp.num_input_start = [$bag.item_quantity(item.db_symbol), max_candy_amount].min
  PFM::Text.set_item_name(item.exact_name)
  scene.display_message(parse_text(22, 198))

  index = $actors.find_index(creature)
  exp_count = Studio::ExpGiveItem.from(item).exp_count * $game_variables[Yuki::Var::EnteredNumber]
  # TODO: Rework this code later to patch in the ExpDistribution global UI (https://app.clickup.com/t/86bzu5w2y)
  $game_system.map_interpreter.give_exp(index, exp_count)
  $bag.remove_item(item.db_symbol, $game_variables[Yuki::Var::EnteredNumber] - 1)
  PFM::Text.reset_variables
end
