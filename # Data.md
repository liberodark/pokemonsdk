# Data

This file explains how to handle data in PSDK.

## Migration from old access to new access

In .25.14 we changed the way to access data, you should no longer access it through the `GameData` module. Instead we created functions to access the data. Here's the list:

* `data_ability(db_symbol)` instead of `GameData::Abilities.anything` (note: you can read name, description, id and db_symbol from `data_ability(db_symbol)`)
* `data_item(db_symbol)` instead of `GameData::Item[db_symbol]`
* `data_move(db_symbol)` instead of `GameData::Skill[db_symbol]`
* `data_creature(db_symbol)` instead of `GameData::Pokemon[db_symbol]` (note: this returns a Specie and not a Pokemon, if you want to access the Pokemon form, please fetch it with data_creature_form)
* `data_creature_form(db_symbol, form)` instead of `GameData::Pokemon[db_symbol, form]`
* `data_quest(db_symbol)` instead of `GameData::Quest[id]`
* `data_trainer(db_symbol)` instead of `GameData::Trainer[id]`
* `data_type(db_symbol)` instead of `GameData::Type[db_symbol]`
* `data_zone(db_symbol)` instead of `GameData::Zone[id]`
* `data_world_map(db_symbol)` instead of `GameData::WorldMap[id]`

Note: You can still use id instead of db_symbol, it uses a different search method.

## Iterate through data

In PSDK the game data is stored in some big collections of main entities, therefore we created methods that allow you to iterate through all the valid data entities. All the method that allow to iterate through data entities starts with `each_data_` followed by the kind of entity and those function either accept a block or return an Enumerator.

Here's the list of methods to iterate through data entity:

* `each_data_ability` : iterate through all abilities
* `each_data_item` : iterate through all items
* `each_data_move` : iterate through all moves
* `each_data_creature` : iterate through all creatures
* `each_data_quest` : iterate through all quests
* `each_data_trainer` : iterate through all trainers
* `each_data_type` : iterate through all types
* `each_data_zone` : iterate through all zones

### FAQ

> How to get the number of entities of a kind the game has ?

Let's say you need to know exactly how many types the game has. You'll write the following code:
```ruby
type_count = each_data_type.size
```

> How to select entities based on some condition ?

To select entities you can use the method `select`. For example, if you want to list all the items that cost 200P you will use this code:
```ruby
all_200p_item = each_data_item.select { |item| item.price == 200 }
```

## Changes in .26

In .26 we changed the data structure to conform with Studio. Thus `GameData` was replaced by `Studio` and some properties completely changed.

For now, .26 make sure that data can be imported from Ruby Host. To do so, remove the folder `Data/Studio` and run the game in `debug`. It should regenerate the whole project data based on Ruby Host data. (Please avoid using Ruby Host after doing so).

### `GameData::Pokemon` => `Studio::Creature`

This class was completely reworked. Now it just hold few information and you need to dig deeper to fetch the extended information about a Pokemon Form.

The `Studio::Creature` class let you access the following:
* id
* db_symbol
* forms
* name (Pikachu)
* species (Mouse Pokémon)
* description (When several of these Pokémon gather, their electricity could build and cause lightning storms.)

The forms array holds a list of Studio::CreatureForm which is similar to `GameData::Pokemon` but has few differences. 

Beware, the forms array does not use index as form identifier, you have to read the form property of each entities to know which form it is.

#### `Studio::CreatureForm`

Here's the list of changes from `GameData::Pokemon` to `Studio::CreatureForm`:
```diff
- id_bis: Integer
- type1: Integer
+ type1: Symbol
- type2: Integer
+ type2: Symbol
- evolution_level: Integer
- evolution_id: Integer
- special_evolution: Array<Hash>
+ evolutions: Array<Studio::CreatureForm::Evolution>
- exp_type: Integer
+ experience_type: Integer
- base_exp: Integer
+ base_experience: Integer
- rareness: Integer
+ catch_rate: Integer
- hatch_step: Integer
+ hatch_steps: Integer
- baby: Integer
+ baby_db_symbol: Symbol
+ baby_form: Integer
- items: Array<Integer>
+ item_held: Array<Studio::CreatureForm::ItemHeld>
- abilities: Array<Integer>
+ abilities: Array<Symbol>
- master_moves: Array<Integer>
- breed_moves: Array<Integer>
- tech_set: Array<Integer>
- move_set: Array<Integer>
+ move_set: Array<Studio::LearnableMove>
```

All the kind of move learning has been regrouped inside move_set, the class defines how the move is supposed to be learnt. See the documentation of each class that replaced integers to know their fields.

### GameData::Item => Studio::Item

Items did not changed much in .26, the main changes are the flags that were renamed, here's the changes:

```diff
- battle_usable: Boolean
+ is_battle_usable: Boolean
- map_usable: Boolean
+ is_map_usable: Boolean
- limited: Boolean
+ is_limited: Boolean
- holdable: Boolean
+ is_holdable: Boolean
+ me(): String
```

Note that the item descriptor has been updated to support Studio::Item instead.

Changes related to `GameData::TechItem` => `Studio::TechItem`:

```diff
- move_learnt: Integer
+ move: Symbol
```

Changes related to `GameData::BallItem` => `Studio::BallItem`:

```diff
- img: String
+ sprite_filename: String
```

Changes related to `GameData::PPIncreaseItem` => `Studio::PPIncreaseItem`:

```diff
- max: Boolean
+ is_max: Boolean
```

Changes related to `GameData::StatBoostItem` => `Studio::StatBoostItem`:

```diff
- stat_index: Integer
+ stat: Symbol
```

Changes related to `GameData::StatusHealItem` => `Studio::StatusHealItem`:

```diff
- status_list: Array<Integer>
+ status_list: Array<Symbol>
```

Changes related to `GameData::StatusConstantHealItem` => `Studio::StatusConstantHealItem`:

```diff
- status_list: Array<Integer>
+ status_list: Array<Symbol>
```

Changes related to `GameData::StatusRateHealItem` => `Studio::StatusRateHealItem`:

```diff
- status_list: Array<Integer>
+ status_list: Array<Symbol>
```

### `GameData::Skill` => `Studio::Move`

As items, move holds some flags and those were renamed, here's the diff:

```diff
- be_method: Symbol
+ battle_engine_method: Symbol
- type: Integer
+ type: Symbol
- pp_max: Integer
+ pp: Integer
- atk_class: Integer
+ category: Symbol
- critical_rate: Integer
+ movecritical_rate: Integer
- direct: Boolean
+ is_direct: Boolean
- charge: Boolean
+ is_charge: Boolean
- recharge: Boolean
+ is_recharge: Boolean
- blocable: Boolean
+ is_blocable: Boolean
- snatchable: Boolean
+ is_snatchable: Boolean
- mirror_move: Boolean
+ is_mirror_move: Boolean
- punch: Boolean
+ is_punch: Boolean
- gravity: Boolean
+ is_gravity: Boolean
- magic_coat_affected: Boolean
+ is_magic_coat_affected: Boolean
- unfreeze: Boolean
+ is_unfreeze: Boolean
- sound_attack: Boolean
+ is_sound_attack: Boolean
- distance: Boolean
+ is_distance: Boolean
- heal: Boolean
+ is_heal: Boolean
- authentic: Boolean
+ is_authentic: Boolean
- bite: Boolean
+ is_bite: Boolean
- pulse: Boolean
+ is_pulse: Boolean
- ballistics: Boolean
+ is_ballistics: Boolean
- mental: Boolean
+ is_mental: Boolean
- non_sky_battle: Boolean
+ is_non_sky_battle: Boolean
- dance: Boolean
+ is_dance: Boolean
- king_rock_utility: Boolean
+ is_king_rock_utility: Boolean
- powder: Boolean
+ is_powder: Boolean
- effect_chance: Integer
+ is_effect_chance: Boolean
- target: Symbol
+ battle_engine_aimed_target: Symbol
- battle_stage_mod: Array<Integer>
+ battle_stage_mod: Array<Studio::Move::BattleStageMod>
- status: Integer
+ move_status: Array<Studio::Move::MoveStatus>
```

Note: priority was changed from 0 -> 14 to -7 -> +7.

### `GameData::Quest` => `Studio::Quest`

Quest model was slightly changed, here's the diff:
```diff
- primary: Boolean
+ is_primary: Boolean
+ resolution: Symbol
```

Changes related to `GameData::Quest::Objective` => `Studio::Quest::Objective`:

```diff
- test_method_name: Symbol
+ objective_method_name: Symbol
- test_method_args: Array
+ objective_method_args: Array
```

Changes related to `GameData::Quest::Earning` => `Studio::Quest::Earning`:

```diff
- give_method_name: Symbol
+ earning_method_name: Symbol
- give_args: Array
+ earning_args: Array
```

### `GameData::Trainer` => `Studio::Trainer`

In .26 trainers hold much more information than .25 thanks to Studio, here's the changes:

```diff
- special_group: Integer
+ battle_id: Integer
- team: Array<Hash>
+ party: Array<Studio::Group::Encounter>
+ is_couple: Boolean
+ ai: Integer
+ bag_entries: Array<Hash>
- internal_names: Array<String>
```

Note: `internal_names` were removed in favor of an entry in CSV files so trainer can have their names translated!

### `GameData::Type` => `Studio::Type`

Types were refined to look less like something coming from the C++ world, here's the diff:

```diff
- on_hit_tbl: Array<Float>
+ damage_to: Array<Studio::Type::DamageTo>
+ color: Color, nil
```

### `GameData::Zone` => `Studio::Zone`

Zone data was heavily updated, in .25 it was holding too much data, now it's just referencing to external data that is easy to fetch & work with. Here's the diff:

```diff
- map_id: Integer
+ maps: Array<Integer>
- worldmap_id: Integer
+ worldmaps: Array<Integer>
- warp_x: Integer
- warp_y: Integer
+ warp: Studio::Zone::MapCoordinate
- pos_x: Integer
- pos_y: Integer
+ position: Studio::Zone::MapCoordinate
- fly_allowed: Boolean
+ is_fly_allowed: Boolean
- warp_dissalowed: Boolean
+ is_warp_disallowed: Boolean
- groups: Array, nil
+ wild_groups: Array<Symbol>
- sub_map
- description
```

### `GameData::WorldMap` => `Studio::Worldmap`

Worldmap cannot be edited with Studio but its internal data was changed since it's being converted to JSON objects. Here's the changes:

```diff
- name_id: Integer
- name_file_id: Integer
- data: Table
+ grid: Array<Array<Integer>>
+ region_name: Studio::CSVAccess
```
