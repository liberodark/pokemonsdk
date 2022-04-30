# Data

This file explains how to handle data in PSDK.

## Migration from old access to new access

In .25.14 we changed the way to access data, you should no longer access it through the `GameData` module. Instead we created functions to access the data. Here's the list:

* `data_ability(db_symbol)` instead of `GameData::Abilities.anything` (note: you can read name, description, id and db_symbol from `data_ability(db_symbol)`)
* `data_item(db_symbol)` instead of `GameData::Item[db_symbol]`
* `data_move(db_symbol)` instead of `GameData::Skill[db_symbol]`
* `data_creature(db_symbol)` instead of `GameData::Pokemon[db_symbol]` (note: this returns a Specie and not a Pokemon, if you want to access the Pokemon form, please fetch it with data_creature_form)
* `data_creature_form(db_symbol, form)` instead of `GameData::Pokemon[db_symbol, form]`
* `data_quest(id)` instead of `GameData::Quest[id]`
* `data_trainer(id)` instead of `GameData::Trainer[id]`
* `data_type(db_symbol)` instead of `GameData::Type[db_symbol]`
* `data_zone(id)` instead of `GameData::Zone[id]`

This change is preparing .26 where `GameData` module will be completely dropped in favor of `Studio` module & `Configs`. Please make sure you're following the changes in your project.

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
type_count = each_data_type.to_a.size
```

> How to select entities based on some condition ?

To select entities you can use the method `select`. For example, if you want to list all the items that cost 200P you will use this code:
```ruby
all_200p_item = each_data_item.select { |item| item.price == 200 }
```
