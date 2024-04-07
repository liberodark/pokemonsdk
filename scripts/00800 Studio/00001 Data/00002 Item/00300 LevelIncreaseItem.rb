module Studio
  # Data class describing an Item that increase the level of the Pokemon
  class LevelIncreaseItem < HealingItem
    # Get the number of level this item increase
    # @return [Integer]
    attr_reader :level_count
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::LevelIncreaseItem) do
  next $game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::LevelIncreaseItem) do |_item, creature|
  next false if creature.egg?

  next (creature.level + 1) <= creature.max_level || creature.evolve_check(:level_up) != false
end

PFM::ItemDescriptor.define_on_creature_use(Studio::LevelIncreaseItem) do |item, creature, scene|
  creature.loyalty -= Studio::HealingItem.from(item).loyalty_malus
  Studio::LevelIncreaseItem.from(item).level_count.times do
    if creature.level_up
      list = creature.level_up_stat_refresh
      Audio.me_play(PFM::ItemDescriptor::LVL_SOUND)
      message = parse_text(22, 128, PFM::Text::PKNICK[0] => creature.given_name, PFM::Text::NUM3[1] => creature.level.to_s)
      scene.display_message_and_wait(message)
      creature.level_up_window_call(list[0], list[1], 40_005)
      scene.message_window.update while scene.message_window && $game_temp.message_window_showing
      # Learn move
      creature.check_skill_and_learn
    end
    # Evolve
    id, form = creature.evolve_check(:level_up)
    GamePlay.make_pokemon_evolve(creature, id, form, false) if id
  end
end

# EXP Candies
# Should be changed for Studio in the future
# https://github.com/PokemonWorkshop/PokemonStudio/issues/73
PFM::ItemDescriptor.define_bag_use(:exp_candy_xs, true) do |item, scene|
  GamePlay.open_party_menu_to_select_pokemon($actors)
  if $game_variables[43] != -1
    amount = 100
    $game_system.map_interpreter.give_exp($game_variables[43], amount)
  else
    next :unused
  end
end

PFM::ItemDescriptor.define_bag_use(:exp_candy_s, true) do |item, scene|
  GamePlay.open_party_menu_to_select_pokemon($actors)
  if $game_variables[43] != -1
    amount = 800
    $game_system.map_interpreter.give_exp($game_variables[43], amount)
  else
    next :unused
  end
end

PFM::ItemDescriptor.define_bag_use(:exp_candy_m, true) do |item, scene|
  GamePlay.open_party_menu_to_select_pokemon($actors)
  if $game_variables[43] != -1
    amount = 3000
    $game_system.map_interpreter.give_exp($game_variables[43], amount)
  else
    next :unused
  end
end

PFM::ItemDescriptor.define_bag_use(:exp_candy_l, true) do |item, scene|
  GamePlay.open_party_menu_to_select_pokemon($actors)
  if $game_variables[43] != -1
    amount = 10000
    $game_system.map_interpreter.give_exp($game_variables[43], amount)
  else
    next :unused
  end
end

PFM::ItemDescriptor.define_bag_use(:exp_candy_xl, true) do |item, scene|
  GamePlay.open_party_menu_to_select_pokemon($actors)
  if $game_variables[43] != -1
    amount = 30000
    $game_system.map_interpreter.give_exp($game_variables[43], amount)
  else
    next :unused
  end
end
