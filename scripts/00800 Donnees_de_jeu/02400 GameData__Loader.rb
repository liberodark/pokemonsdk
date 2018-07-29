#encoding: utf-8

# If PSDK works in 4G mode or not
# @note Not implemented yet
GameData::Flag_4G = false

#> Chargement des natures
$game_data_natures = load_data("Data/PSDK/Natures.rxdata")

#> Chargement des types
$game_data_types = load_data("Data/PSDK/Types.rxdata")

#> Chargement des association talentID -> TextID
$game_data_abilities = load_data("Data/PSDK/Abilities.rxdata")

#> Chargement des attaques
$game_data_skill = load_data("Data/PSDK/SkillData.rxdata")
# LastID of the Skill data
GameData::Skill::LastID = $game_data_skill.size - 1
$game_data_skill[0] = GameData::Skill.new(0, :s_basic, 0, 0, 0, 5, :none, 2, 
  false, 0, 0, false, false, false, false, false, false, false, false, 0, 
  [0,0,0,0,0,0,0,0], 0,
)

#> Chargement des Pokémon
$game_data_pokemon = load_data("Data/PSDK/PokemonData.rxdata")
# LastID of the Pokemon data
GameData::Pokemon::LastID = $game_data_pokemon.size - 1
$game_data_pokemon[0] = [GameData::Pokemon.new(1.60, 52, 0, 1, 1, 1, 1, 1, 1, 1,
  1, 0, 0, 0, 0, 0, 0, [], [], 0, 0, nil, 1, 100, 0, 0, 60, [0,0,0], [15, 15], 
  [], [], 10**9, [0,0, 0, 0], 0)]

#> Chargement des Objets
$game_data_item = load_data("Data/PSDK/ItemData.rxdata")
# LastID of the Item data
GameData::Item::LastID = $game_data_item.size - 1

#> Chargement des données de la carte du monde
_arr = load_data("Data/PSDK/MapData.rxdata")
$game_data_zone = _arr[1] #> Zones, informations essentielles sur la carte parcourue
$game_data_map  = _arr[0] #> Données de la carte du monde (placement des zones)

#> Chargement des équipes de dresseur (tests)
#$game_data_teams = load_data("Data/PSDK/Teams.rxdata")

#> Chargement des maplinks
$game_data_maplinks = load_data("Data/PSDK/Maplinks.rxdata")
=begin
game_title = Kernel.get_string("Game","Title")
if(game_title and game_title.include?("mon SDK"))
  $game_data_maplinks = {# n_id, n_addx, e_id, e_addy, s_id, s_addx, o_id, o_addy
    1 => [0, 0, 9, -3, 0, 0, 0, 0],
    9 => [0, 0, 0, 0, 7, -3, 1, 3],
    11 => [11, 0, 11, 0, 11, 0, 11, 0]
  }
  #save_data($game_data_maplinks, "Data/PSDK/Maplinks.rxdata")
else
  $game_data_maplinks = {}
end
=end

#> Chargement des données de systemtag
$data_system_tags = load_data("Data/PSDK/SystemTags.rxdata")

#> Chargement des données des quêtes
$game_data_quest = load_data("Data/PSDK/Quests.rxdata")

#> Chargement des dresseurs
$game_data_trainer = load_data("Data/PSDK/Trainers.rxdata")

#> Chargement des symbol des capacités
unless File.exist?('Data/PSDK/Abilities_Symbols.rxdata')
  #> Update symbols
  require "plugins/update_db_symbol.rb"
end
GameData::Abilities.load_symbols(load_data('Data/PSDK/Abilities_Symbols.rxdata'))
