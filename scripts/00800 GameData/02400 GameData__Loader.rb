# If PSDK works in 4G mode or not
# @note Not implemented yet
GameData::Flag_4G = false

Graphics.on_start do
  # Load natures
  $game_data_natures = load_data('Data/PSDK/Natures.rxdata')

  # Load Types
  $game_data_types = load_data('Data/PSDK/Types.rxdata')

  # Load association abilityID -> TextID
  $game_data_abilities = load_data('Data/PSDK/Abilities.rxdata')

  # Load Moves
  $game_data_skill = load_data('Data/PSDK/SkillData.rxdata')
  # set the LastID of the Skill data
  GameData::Skill.const_set(:LastID, $game_data_skill.size - 1)
  $game_data_skill[0] = GameData::Skill.new(
    0, :s_basic, 0, 0, 0, 5, :none, 2, false, 0, 0, false, false, false, false,
    false, false, false, false, 0, Array.new(8, 0), 0
  )

  # Load Pokemon
  $game_data_pokemon = load_data('Data/PSDK/PokemonData.rxdata')
  # set the LastID of the Pokemon data
  GameData::Pokemon.const_set(:LastID, $game_data_pokemon.size - 1)
  $game_data_pokemon[0] = [GameData::Pokemon.new(
    1.60, 52, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, [], [], 0, 0, nil, 1,
    100, 0, 0, 60, [0, 0, 0], [15, 15], [], [], 10**9, [0, 0, 0, 0], 0
  )]

  # Load the items
  $game_data_item = load_data('Data/PSDK/ItemData.rxdata')
  # set LastID of the Item data
  GameData::Item.const_set(:LastID, $game_data_item.size - 1)

  # Load WorldMap & Zone data
  $game_data_map, $game_data_zone = load_data('Data/PSDK/MapData.rxdata')

  # Load Maplinks
  $game_data_maplinks = load_data('Data/PSDK/Maplinks.rxdata')

  # Load SystemTags
  $data_system_tags = load_data('Data/PSDK/SystemTags.rxdata')

  # Load Quests
  $game_data_quest = load_data('Data/PSDK/Quests.rxdata')

  # Load Trainers
  $game_data_trainer = load_data('Data/PSDK/Trainers.rxdata')
end

# Load Ability symbols
unless File.exist?('Data/PSDK/Abilities_Symbols.rxdata')
  # Update symbols
  require 'plugins/update_db_symbol.rb' unless $RELEASE
end
GameData::Abilities.load_symbols(load_data('Data/PSDK/Abilities_Symbols.rxdata'))
