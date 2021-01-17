# PSDK .25 BE 

This page describe many things about Pokémon SDK .25 Battle Engine

## How things works

The Battle Engine is separated by 3 main instances
- `Battle::Scene` this instance is responsible of holding and instanciating the other two instances. That's the scene and it will gather and send the user input to the logic.
- `Battle::Visual` this instance is responsible of holding all the graphics of the Battle. We can query this instance to show specific things of the battle scene like the player choice or get a Pokemon visual battler.
- `Battle::Logic` this instance is responsible of holding the battle logic. It gives access to several handler like the handler of status changes, it also help to access a Pokemon Battler (the object containing the data).

All of those instance has a specific task (as described) and will only be responsive of the said task. This allow the battle to be more dynamic. For example, if you want to change how the battle looks like you only need to plug another Visual instance to the battle scene and it will work seamlessly.

## How to access those main objects
### The battle scene object

The battle scene object is normally accessible from anywhere, the battle engine is designed such a way that the instance variable `@scene` always contains a `Battle::Scene` object. We strongly discourage accessing the battle scene from the global `$scene` (especially if you seek the logic/visuals) because it's not guarenteed that this global contains the battle scene.

If you're implementing effects or hooks, you may get a `handler`. This handler should provide a `scene` property you can use to get the battle scene.

Note: The visual and the logic doesn't provide an external access to the battle scene. **They should always pass the reference to the objects they instanciate!**

### The logic object

If you're able to get the battle scene object, you'll get the logic object by using the `logic` property of the battle scene object. In some cases (effects, moves, handlers) the logic object is accessible from the `@logic` instance variable.

The handlers will always provide access to the logic (either from parameter or from property).

### The visual object

Unless it was passed down as parameter of the object you're manipulating, it will always be accessible through property visual of the battle scene object.

## The generic stuff
### Displaying a message

To display a message, you'll call the function `display_message(string)` from the battle scene. This method will block the rest of the execution until the message has finished to be shown.

To get the string, you may call `parse_text(file_id, text_id)` (generally with file 18) or `parse_text_with_pokemon(file_id, text_id, pokemon)` (generally with file 19). See how it is called to guess how to use those functions.

Example:
```ruby
@scene.display_message(parse_text(18, 25))
```

### Displaying the ability of a Pokémon

Call the function `show_ability(pokemon)` from the `visual` object. This function will shows the ability name near to the Pokémon and does not block the execution.

Example:
```ruby
@scene.visual.show_ability(target)
```

### Displaying the item held by a Pokémon

Call the function `show_item(pokemon)` from the `visual` object. This function shows the item held near to the Pokémon and does not block the execution.

Example:
```ruby
@scene.visual.show_item(user)
```

### Display the animation showing the transformation of a Pokemon

Several Pokémon change their appearance during battle, to show this assign the new appearence to the Pokémon and then call the function `show_switch_form_animation(pokemon)` from the `visual` object. This function blocks the execution.

Example:
```ruby
pokemon.form = 5
@scene.visual.show_switch_form_animation(pokemon)
```

### Display a Move animation

To explictely show a move animation you can call the function `show_move_animation(user, targets, move)` from the `visual` object.

Example:
```ruby
@scene.visual.show_move_animation(user, targets, user.moveset[0])
```

### Display a generic animation

Sometimes you need to show a generic animation over a specific Pokémon (or not but you have to specify a Pokémon anyway). To do this, use the function `show_rmxp_animation(target, rmxp_id)`.

This function will be deprecated in the future (replaced by something else) so don't use it unless you have no other choice.

## The handlers

In order to get the thing clean, we use handlers to handle the generic things that can happen during battle. Here's the handler that currently exists:

- `StatChangeHandler` : Manage the stat changes, can be accessed through `logic.stat_change_handler`.
- `ItemChangeHandler` : Manage the swapping of item over a Pokémon, can be accessed through `logic.item_change_handler`
- `StatusChangeHandler` : Manage the status changes, can be accessed through `logic.status_change_handler`
- `DamageHandler` : Manage the damage & drain over Pokémon, can be accessed through `logic.damage_handler`
- `SwitchHandler` : Manage the switches between Pokémon, can be accessed through `logic.switch_handler`
- `EndTurnHandler` : Manage the end of turn sequence, can be accessed through `logic.end_turn_handler`. **This is not a change handler, this mean it doesn't act as the other handlers!**
- `WeatherChangeHandler` : Manage the weather condition changes, can be accessed through `logic.weather_change_handler`
- `FleeHandler` : Manage the flee sequence (& calculation), can be accessed through `logic.flee_handler`
- `CatchHandler` : Manage the calculations related to catching the Pokemon, can be accessed through `logic.catch_handler`
- `AbilityChangeHandler` : Manage the change ability procedure, can be accessed through `logic.ability_change_handler`
- `BattleEndHandler` : Manage the everything that happends at the end of the battle
- New handlers ???

**Important note about the handlers**: the logic instanciate a new handler everytime you call the function that give access to the handler. If you need to show the prevention reason when you don't call the `*_with_process` function but use the test function instead, it's recommanded to store the handler in a local variable.

### ChangeHandlerBase

The class `Battle::Logic::ChangeHandlerBase` implements the basic functionality of all change handlers:

- The attribute `scene` giving you access to the scene inside the hooks.
- The attribute `logic` giving you access to the logic inside the hooks.
- The method `process_prevention_reason` that execute the block passed through `prevent_change`.
- The method `prevent_change(&block)` that returns `:prevent` and store the block as prevention_reason. This method can be called inside the prevention hooks in order to stop the prevention checking and tell that the change is not possible.

### StatChangeHandler

This handler is responsive of telling if it is possible to change the stats, why not and apply the stat change.

Methods you can call:
- `stat_increasable?(stat, target, launcher = nil, skill = nil)` : Tells if the `stat` can be increased on the `target`. You can pass `launcher` and `skill` during the move procedure execution to help the prevention upons move use.
- `stat_decreasable?(stat, target, launcher = nil, skill = nil)` : Tells if the `stat` can be decreased on the `target`. You can pass `launcher` and `skill` during the move procedure execution to help the prevention upons move use.
- `stat_change(stat, power, target, launcher = nil, skill = nil)` : Actually change the `stat` with the amount specified by `power` (negative = decrease) on the `target`. If the resulting power is 0, the apprioriate message will be shown, the animation is also played from here. You can pass `launcher` and `skill` during the move procedure execution to help the prevention upons move use.
- `stat_change_with_process(stat, power, target, launcher = nil, skill = nil)` : does the same as `stat_change` but call the test methods before and show the prevention reason if any.

The stats you can change:
- `:atk` : Physical attack of the Pokémon
- `:dfe` : Physical defense of the Pokémon
- `:ats` : Special attack of the Pokémon
- `:dfs` : Special defense of the Pokémon
- `:spd` : Speed of the Pokémon
- `:acc` : Accuracy of the Pokémon
- `:eva` : Evasion of the Pokémon

Example:
```ruby
logic.stat_change_handler.stat_change_with_process(:atk, -2, target)
```

#### How to prevent a stat from being changed

You can define a prevention hook or rely on the effects to do this. The effect side will be shown later. 

There's two kind of stat change you can prevent:
- Stat increase: by calling `register_stat_increase_prevention_hook(reason)` from the `StatChangeHandler` class.
- Stat decrease: by calling `register_stat_decrease_prevention_hook(reason)` from the `StatChangeHandler` class.

Please note that the reason has to be unique, otherwise the previous call of the method having the same name will be overwritten by the new one. 

Example:

```ruby
Battle::Logic::StatChangeHandler.register_stat_decrease_prevention_hook('No atk decrease caused by foe moves') do |handler, stat, target, launcher, skill|
  next unless launcher && skill # Only prevented during move execution
  next if stat != :atk # Only block atk changes
  next if target.ability_db_symbol != :atk_blocker # Only work if the target has the right ability

  next handler.prevent_change do
    handler.scene.visual.show_ability(target)
    handler.scene.display_message(parse_text_with_pokemon(19, 2563125, target))
  end
end
```

#### How to change the power of a stat change

There's a hook allowing to potentially change the power of a stat change. To do this, call the method `register_stat_change_hook(reason)` from the class `StatChangeHandler`.

Example: 
```ruby
Battle::Logic::StatChangeHandler.register_stat_change_hook('PSDK stat_change: Simple') do |handler, stat, power, target, launcher, skill|
  next if target.ability_db_symbol != :simple # The target needs the right ability

  # We make sure the user of the move (if any) doesn't have mold_breaker
  if !launcher || launcher.can_be_lowered_or_canceled?(true)
    handler.scene.visual.show_ability(target)
    next power * 2 # We double the power
  end
  next nil # Returning nil (or just writing next) doesn't change the power
end
```

### ItemChangeHandler

This handler is responsive of replacing the item held by the Pokémon. The only method you can call from this handler is `change_item(db_symbol, overwrite, target, launcher = nil, skill = nil)`.

As most handler, it can be called during moves so launcher & skill are optional. The `db_symbol` should be the new item held by the pokemon, use `:none` to remove the item held by the Pokémon (please don't call your items None). The `overwrite` parameter should be set to `true` if you want to permanently change the item (usually it's consumable items that sets this parameter to true).

#### How to prevent an item from being changed

This handler allows to prevent item from being changed using the function `register_pre_item_change_hook(reason)` of the `ItemChangeHandler` class.

Example:

```ruby
Battle::Logic::ItemChangeHandler.register_pre_item_change_hook('Infinite spikes are there forever') do |handler, db_symbol, target, launcher, skill|
  next if target.battle_item_db_symbol != :infinite_spikes # Don't change if target has no infinite spikes

  next handler.prevent_change do
    handler.scene.visual.show_item(target)
    handler.scene.display_message(parse_text_with_pokemon(19, 2354654, target))
  end
end
```

#### How to execute an action when an item has been changed

This handler allows you to execute actions after an item was changed on the target (example unburden). To define this kind of action call the function `register_post_item_change_hook(reason)` from the class `ItemChangeHandler`.

Example:

```ruby
Battle::Logic::ItemChangeHandler.register_post_item_change_hook('PSDK item change post: Unburden') do |handler, db_symbol, target|
  # Don't execute if we didn't removed the item or the target doesn't have the unburden ability
  next if db_symbol != :none || target.ability_db_symbol != :unburden

  # If wa can increase speed we do otherwise remain silent
  if (st_ch = handler.logic.stat_change_handler).stat_increasable?(:spd, target)
    handler.scene.visual.show_ability(target)
    st_ch.stat_change(:spd, 1, target)
  end
end
```

### StatusChangeHandler

This handler is responsible of telling if a status can be applied (including confusion & flinch) and apply it if requested.

Here's the list of method you can call from this handler:
- `status_appliable?(status, target, launcher = nil, skill = nil)` : To test if you can apply the status.
- `status_change(status, target, launcher = nil, skill = nil, message_overwrite: nil)` To change the status.
- `status_change_with_process(status, target, launcher = nil, skill = nil, message_overwrite: nil)` : To test if the status is appliable and to change it if so.

The same way of other handlers, you can pass launcher and skill during the move procedure to tell explicitely that the status change comes from a move.
The parameter `message_overwrite` is the id of the message in file 19 if you want to show something else than the regular status change message.

The status you can apply are the following:
- `:poison` : to set the poison status condition
- `:toxic` : to set the bad poison status condition
- `:confusion` : to confuse the Pokémon
- `:sleep` : to set the asleep status condition
- `:freeze` : to set the frozen status condition
- `:paralysis` : to set the freeze status condition
- `:burn` : to set the burn status condition
- `:cure` : to cure the status condition

#### How to prevent a status from being applied

This handler allows you to prevent change of status by registering a status_prevention hook. Here's an example:

```ruby
Battle::Logic::StatusChangeHandler.register_status_prevention_hook('Poison imunity') do |handler, status, target, launcher, skill|
  next if status != :poison && status != :toxic # We only want to prevent poisoning
  next if target.ability_db_symbol != :poison_imunity # No prevention if the right ability is not on target

  next handler.prevent_change do
    handler.scene.visual.show_ability(target)
    handler.scene.display_message(parse_text_with_pokemon(19, 22354, target))
  end
end
```

#### How to execute an action after a status was applied

Sometimes stuff happens after a status was applied, this handler allows you to define a hook that can trigger other stuff after the status was changed. Example:

```ruby
Battle::Logic::StatusChangeHandler.register_post_status_change_hook('Sleep evasion') do |handler, status, target, launcher, skill|
  next if status != :sleep # Only happen on sleep application
  next if target.ability_db_symbol != :sleep_evasion

  if (stat_handler = handler.logic.stat_change_handler).stat_increasable?(:eva, target)
    handler.scene.visual.show_ability(target)
    stat_handler.stat_change(:eva, 6, target)
  end
end
```

### DamageHandler

This handler is responsive of telling if damages can be applied on a Pokémon and deal them. It also include the draining damage kind so it's easier to manage draining.

List of method you can call from this handler:
- `damage_appliable(hp, target, launcher = nil, skill = nil)` give the actual number of damage the target will take or false if no damage can be applied.
- `damage_change(hp, target, launcher = nil, skill = nil)` if hp is positive, deal damage to the target, otherwise heals the target.
- `damage_change_with_process(hp, target, launcher = nil, skill = nil)` calculate the actual damage that can be applied (or if that's not possible to deal damages) and apply them if possible.
- `drain(hp_factor, target, launcher, skill = nil)` drains a factor amount of hp on the target (max_hp / hp_factor) and heals the launcher with that taken amount (unless an ability tells otherwise).
- `drain_with_process(hp_factor, target, launcher, skill)` check first the actual damage the target can take (substitute & co) and then drain the result if possible.

This handler allows you to overwrite hp taken by the target or prevent a hp change using the damage_prevention hook:

```ruby
# Preventing damages
Battle::Logic::DamageHandler.register_damage_prevention_hook('Even damage ability') do |handler, hp, target, launcher, skill|
  next if hp.odd? || hp <= 0 # Target only take even hp damage
  next if target.ability_db_symbol != :even_damage # Target need the right ability

  next handler.prevent_change do
    handler.scene.visual.show_ability(target)
    handler.scene.display_message(parse_text_with_pokemon(19, 22354, target))
  end
end

# Changing damages
Battle::Logic::DamageHandler.register_damage_prevention_hook('Half damage ability') do |handler, hp, target, launcher, skill|
  next if hp <= 0 # We don't divid healing hp
  next if target.ability_db_symbol != :half_damages # Target need the right ability

  next hp / 2
end
```

In addition of dealing damages, it is possible to execute actions when the target has taken the damage or got K.O.'d. The DamageHandler calls on of the following hooks depending on if the target is still able to fight or not:

```ruby
# After damage hooks
Battle::Logic::DamageHandler.register_post_damage_hook('Increase atk afte damages') do |handler, hp, target, launcher, skill|
  next unless launcher && skill # Only work if damages are move related
  next if hp <= 0 # No increase upons heal
  next if target.ability_db_symbols != :angry_damages # Target needs the right ability

  if (stat_handler = handler.logic.stat_change_handler).stat_increasable?(:atk, target)
    handler.scene.visual.show_ability(target)
    stat_handler.stat_change(:atk, 1, target)
  end
end

# After death hook
Battle::Logic::DamageHandler.register_post_damage_death_hook('Not dying alone') do |handler, hp, target, launcher, skill|
  next unless launcher && skill # Only work if damages are move related
  next if target.ability_db_symbols != :not_dying_alone # Target needs the right ability

  handler.scene.visual.show_ability(target)
  # We ignore all abilities & stuff preventing damages:
  handler.logic.damage_handler.damage_change(launcher.hp, launcher)
end
```

### SwitchHandler

The SwitchHandler is responsive of telling wether the pokemon can switch and execute all the events that triggers during switch (eg. entry hazard).

Here's the methods you can call from this handler:
- `can_switch?(pokemon, skill = nil)` : Tell if the pokemon can be switched, a move can be passed if it was caused by a "switching like" move.
- `execute_switch_events(who, with)` : Actually execute the switch events.

**Note**: The execute_switch_events is called from `perform_action_switch` in the logic.
It is recommended to call the function from logic if you want to actuall perform a switch.

Example:
```ruby
logic.perform_action_switch(type: :switch, with: with, who: who)
```
The parameter with is the Pokémon comming to the battle, the parameter who is the pokemon being replaced.

#### How to ensure a switch will happen
Since some items/ability allows the pokemon to switch regardless of the blocking condition, this handler look at the switch_passthrough hook.

Example:
```ruby
Battle::Logic::SwitchHandler.register_switch_passthrough_hook('Coward ability') do |handler, pokemon, skill|
  next if pokemon.ability_db_symbol != :coward

  next :passthrough # Actually force the switch
end
```

#### How to prevent a pokemon from switching

If the Pokemon has no condition allowing it to switch regardless of the condition, you can prevent the Pokemon from switching using the switch_prevention hook.

Example:
```ruby
Battle::Logic::SwitchHandler.register_switch_prevention_hook('PSDK switch prev: Shadow Tag') do |handler, pokemon|
  next if pokemon.ability_db_symbol == :shadow_tag
  next unless (fv = handler.logic.foes_of(pokemon).find { |foe| foe&.alive? && foe.ability_db_symbol == :shadow_tag })

  next handler.prevent_change do
    handler.scene.visual.show_ability(fv)
  end
end
```

#### How to execute something happening after a switch

It is possible to execute action right after a switch using the switch_event hook:

```ruby
Battle::Logic::SwitchHandler.register_switch_event_hook('PSDK switch: Pressure') do |handler, who, with|
  next if with.ability_db_symbol != :pressure

  handler.scene.visual.show_ability(with)
  handler.scene.display_message(parse_text_with_pokemon(19, 487, with))
end
```

Note that the BattleEngine switch the Pokémon with themself during the very first turn (before asking the actions) in order to allow some ability to trigger. You can detect that using this condition: `who == with`

### EndTurnHandler

A lot of stuff happens during the end of turns, it is possible to define your actions using the end_turn_event hook.

Example:

```ruby
Battle::Logic::EndTurnHandler.register_end_turn_event('PSDK end turn: Rain') do |logic, scene, battlers|
  next if $env.current_weather != 1

  if $env.decrease_weather_duration # Return true if stopping!
    scene.display_message(parse_text(18, 93))
    logic.weather_change_handler.weather_change(:none, 0)
  else
    scene.visual.show_rmxp_animation(battlers.first || logic.battler(0, 0), 493)
  end
end
```

### WeatherChangeHandler

In order to be able to change the weather properly, there's a handler telling if weather can be changed and what happen after the weather got changed.

Here's the methods you can call from the WeatherChangeHandler:
- `weather_appliable?(weather_type)` Tell if the weather can be applied
- `weather_change(weather_type, nb_turn)` Change the weather for a specific amount of turn (nb_turn = nil means never stops)
- `weather_change_with_process(weather_type, nb_turn)` Check if the weather can be changed and change it.

Here's the list of weather types:
- `:none` : No weather
- `:rain` : Raining
- `:sunny` : Sunny Day weather
- `:sandstorm` : Sandstorm
- `:hail` : Hail
- `:fog` : Fog

#### How to prevent weather from being changed

This handler look at the weather_prevention hook to know if the weather can be changed or not, here's an example:

```ruby
Battle::Logic::WeatherChangeHandler.register_weather_prevention_hook('PSDK prev weather: Cloud Nine') do |handler, weather|
  next if weather == :none # We don't prevent weather removal
  # We try to find a pokemon that has the cloud nine ability
  next unless (cloud_nine = handler.logic.all_alive_battlers.find { |battler| battler.ability_db_symbol == :cloud_nine })

  # We prevent the change telling which pokemon was the one preventing
  handler.prevent_change do
    handler.scene.visual.show_ability(cloud_nine)
  end
end
```

#### How to execute an action when the weather was changed

This handler executes all the post_weather_change hooks once the weather was sucessfully changed.

Here's an example of post_weather_change hook:
```ruby
Battle::Logic::WeatherChangeHandler.register_post_weather_change_hook('PSDK post weather: Ensure form switch on weather') do |handler|
  handler.logic.all_alive_battlers.each do |battler|
    next unless battler.form_calibrate(:weather)

    handler.scene.visual.show_switch_form_animation(battler)
  end
end
```

### FleeHandler

This handler is responsive of telling if it is possible to flee or not. Normally you should not have to call it yourself because it's related to the Player flee action. However if you want to add conditions that prevents the player from fleeing (without preventing him from doing anything else) you can use the flee_block hook.

Here's an example:

```ruby
Battle::Logic::FleeHandler.register_flee_block_hook('No flee when BT_NoEscape is on') do |handler|
  next unless $game_switches[Yuki::Sw::BT_NoEscape]

  handler.prevent_change do
    handler.scene.display_message(parse_text(18, 77))
  end
end
```

If you want the player to be able to flee (eg, having the Pokemon holding smoke ball) you can use the `flee_passthrough` block. If this block returns :success, the rate calculation & the switch handler will not be invoked!

Here's an example:
```ruby
Battle::Logic::FleeHandler.register_flee_passthrough_hook('PSDK smoke ball') do |handler, pokemon|
    next if pokemon.item_db_symbol != :smoke_ball

    # Play smokeball animation over pokemon
    message = parse_text_with_pokemon(19, 1010, pokemon, PFM::Text::ITEM2[1] => pokemon.item_name)
    handler.scene.display_message_and_wait(message)
    next :success
  end
end

### CatchHandler

This handler is responsive of calculating of the enemy Pokémon can be caught and showing the sequence of catching the Pokémon (including animation & message).

#### How to define a new ball

It is possible to have specific calculation depending on the type of ball, to do so, call `Battle::Logic::CatchHandler.add_ball_rate_calculation(db_symbol)`

This function takes `db_symbol` as the db_symbol of the ball item and a block that is feeded with the following arguments:
- `target` : The PFM::PokemonBattler object of the Pokémon that should be caught
- `pkm_ally` : The PFM::PokemonBattler object of the Player's Pokémon.

The block should return the final rate of the ball (so you should return a modified version of target.rareness).

Example:
```ruby
Battle::Logic::CatchHandler.add_ball_rate_calculation(:dive_ball) do |target, _pkm_ally|
  next (target.rareness * 3.5) if @scene.battle_info.fishing
  next (target.rareness * 3.5) if $game_player.surfing?

  next target.rareness
end
```

Note: Beast ball is not implement through add_ball_rate_calculation!

#### How to define a beast Pokémon

Add its db_symbol to `Battle::Logic::CatchHandler::ULTRA_BEAST`.

Example:
```ruby
Battle::Logic::CatchHandler::ULTRA_BEAST << :pheromosa
```

### AbilityChangeHandler

This handler is responsive of checking if an ability can be changed on the Pokemon and perform the change if requested.

There's several kind of change that can be prevented.

#### Ability on the target that cannot be changed

If a Pokemon hold any of the ability defined in `Battle::Logic::AbilityChangeHandler::CANT_OVERWRITE_ABILITIES` you cannot change its ability to another ability.

To define such ability, just add its db_symbol to the constant. Example:
```ruby
Battle::Logic::AbilityChangeHandler::CANT_OVERWRITE_ABILITIES << :multitype
```

#### Target ability that cannot be changed depending on the move

When a Pokemon use a move against a target, it is possible that some ability of the target prevents the target ability to be changed. To do so, define the list a target ability that prevent a move from changing the ability this way:

```ruby
Battle::Logic::AbilityChangeHandler::SKILL_BLOCKING_ABILITIES[mov_db_symbol] = [ability_db_symbol1, ability_db_symbol2, ...]
```

#### Abilities that cannot overwrite target ability

Sometimes you need to specify a list of abilities that cannot be overwritten if you want to change target ability with this ability. To do so define the list this way:
```ruby
Battle::Logic::AbilityChangeHandler::ABILITY_BLOCKING_ABILITIES[ability_to_change_db_symbol] = [target_ability_db_symbol1, target_ability_db_symbol2, ...]
```

Example:
```ruby
Battle::Logic::AbilityChangeHandler::ABILITY_BLOCKING_ABILITIES[:trace] = %i[flower_gift forecast illusion imposter trace]
```

Don't forget that some cases are already handled by `Battle::Logic::AbilityChangeHandler::CANT_OVERWRITE_ABILITIES`.

### BattleEndHandler

This handler handle every actions that happends at the end of the battle. For example, the trigger of the pickup ability, returning to the Pokemon Center when defeated, etc...

You can define stuff that happens at the end of the battle using those two methods:
- `Battle::Logic::BattleEndHandler.register('Reason') do |handler, players_pokemon| end`
- `Battle::Logic::BattleEndHandler.register_no_defeat('Reason') do |handler, players_pokemon| end`

The block sent to `register_no_defeat` are not called if the result is defeat.
The variable `handler` allows you to access the battle scene and the variable `players_pokemon` contains the PokemonBattler of the Player. You will need to call the `.original` method to get the actual Pokemon in the party in case you want to change something on the Pokemon.

Example:
```ruby
Battle::Logic::BattleEndHandler.register_no_defeat('PSDK honey gather') do |_, players_pokemon|
  players_pokemon.each do |pokemon|
    next unless pokemon.original.ability_db_symbol == :honey_gather && pokemon.original.item_holding == 0 && rand(100) < (pokemon.level / 2)

    pokemon.original.item_holding = GameData::Item[:honey].id
  end
end
```

## The effects

The effects in the battle engine are objects that execute an action on any hooks of the handlers. The effects all inherit from `Battle::Effects::EffectBase`. Those effects can have a counter, can be killed (then removed from their respective stack).

You can find effects at several places:
- `logic.terrain_effects` : On terrain (affecting everything)
- `logic.bank_effects[bank]` : On banks (affecting Pokémon of this bank)
- `logic.position_effects[bank][position]` : On specific position (affecting the Pokémon on this position)
- `pokemon.effects` : On a specific Pokémon

All those places holds a `Battle::Effects::EffectsHandler` object allowing you to manage the effect through the following methods:

- `has?(symbol)` : Tell you if the handler contains an effect named by the symbol input
- `add(effect)` : Add a new effect to the handler
- `get(symbol)` : Get the first effect that is named by the symbol input
- `each { |effect| ... }` : Execute a block getting each effects as parameter
- `deleted_dead_effects` : Remove all dead effects from the handler

When a handler is called, all the effect related to the pokemon involved in the handler are called in the following order:
1. `logic.terrain_effects`
2. For each pokemon involved:
   1. `pokemon.effects`
   2. `logic.position_effects[pokemon.bank][pokemon.position]`
3. For each bank involved (guessed from involved pokemon):
   1. `logic.bank_effects[bank]`

**Note**: If any effect block returns a Symbol, iteration over all effect is stoppoed and the Symbol is returned.

### How to define a hook inside effect?

All effect inheriting from `Battle::Effects::EffectBase` has methods called `on_{hook_type}` you can overwrite in order to specify the behaviour you want for your effect. Since all hook methods are called from the effects, they always return nil or a neutral result when they're not defined.

Here's the list of methods you can define to hook something on an effect:
- `on_stat_increase_prevention(handler, stat, target, launcher, skill)`
- `on_stat_decrease_prevention(handler, stat, target, launcher, skill)`
- `on_stat_change(handler, stat, power, target, launcher, skill)`
- `on_pre_item_change(handler, db_symbol, target, launcher, skill)`
- `on_post_item_change(handler, db_symbol, target, launcher, skill)`
- `on_status_prevention(handler, status, target, launcher, skill)`
- `on_post_status_change(handler, status, target, launcher, skill)`
- `on_damage_prevention(handler, hp, target, launcher, skill)`
- `on_post_damage(handler, hp, target, launcher, skill)`
- `on_post_damage_death(handler, hp, target, launcher, skill)`
- `on_switch_passthrough(handler, pokemon, skill)`
- `on_switch_prevention(handler, pokemon, skill)`
- `on_switch_event(handler, who, with)`
- `on_end_turn_event(logic, scene, battlers)`
- `on_weather_prevention(handler, weather_type, last_weather)`
- `on_post_weather_change(handler, weather_type, last_weather)`
- `on_move_prevention_user(user, targets, move)`
- `on_move_prevention_target(user, target, move)`
- `on_move_type_change(user, target, move, type)`

Here's an example of effect that defines a behaviour:
```ruby
module Battle
  module Effects
    # Implement the attract effect
    class Attract < PokemonTiedEffectBase
      # Get the Pokemon who's this Pokemon is attracted to
      # @return [PFM::PokemonBattler]
      attr_reader :attracted_to
      # Create a new Pokemon Attract effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param attracted_to [PFM::PokemonBattler]
      def initialize(logic, target, attracted_to)
        super(logic, target)
        @attracted_to = attracted_to
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        return if user != @pokemon
        return unless targets.include?(@attracted_to)

        move.scene.display_message(parse_text_with_pokemon(19, 333, user, PFM::Text::PKNICK[1] => @attracted_to.given_name))
        if rand(2) == 1
          move.scene.display_message(parse_text_with_pokemon(19, 336, user))
          return :prevent
        end
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :attract
      end
    end
  end
end
```

This effect has the name `:attract` so we can detect that it's already applied to the pokemon like this: `pokemon.effects.has?(:attrack)`. Each time the user will try to use a move on a target, the method `on_move_prevention_user` will be called and will potentially prevents the user to use the move on the specified target.

If you want to manage some properties of the effect here's the methods you can find on an effect:
- `counter=(new_counter)` : allows you to set how many turn the effect is active
- `dead?` : allows you to know/specify if the effect is dead or not (implying it'll get removed at the very last after all the end turn actions)
- `name` : gives you the symbol name of the effect (helping the effect handler to detect the effect with `has?(symbol)`)
- `kill` : Kills the effect.
- `on_delete` : Function that is called after the effect was removed from its handler. It allows you to specify a message.

## The moves

In the new Battle engine, the moves have their own object in the Battle module. This allow to specify several kind of Move using inheritance for several "be_methods".

All moves should inherit from `Battle::Move` if a be_method for move is not defined, the behaviour of the move can be highly impredictible!

### How to define a move be_method ?

Once you defined the move class, you can call the following static method of `Battle::Move` : `register`. Example: `Battle::Move.register(:s_basic, Battle::Move::Basic)`.

Once you did this, all the move whose be_method correspond to the first parameter of register will be instancied with the class given by the second parameter of register.

### What are the methods of the moves ?

Here's the list of important methods you'll find in the moves:

- `damages(user, target, rng)` : Calculate the damages the move will deal to target, sets the `effectiveness` factor and the `critical` boolean attribute. This method should remain silent so abilities & items involved in rate modification should not be shown during the calculation. We will not detail all the methods involved in the calculation in this chapter.
- `type_modifier(user, target)` : Calculate the effectiveness of the move against a target. **This method is not called in damages**.
- `calc_stab(user)` : Gives the stab of the move with a specific user.
- `calc_type_n_multiplier(target, type_to_check, types)` : Gives the type modifier of the wanted type_to_check (`:type1`, `:type2`, `:type3`) on target when the move will hit the target. `types` correspond to the move types.
- `definitive_types(user, target)` : Gives the list of types the move has once all effect that change types were processed.
- `one_target?` : Tells if the move can hit only one target each time it's used.
- `no_choice_skill?` : Tell if the move let the player choose the target.
- `battler_targets(pokemon, logic)` : List all the possible targets of the move depending on the pokemon who use the move.
- `chance_of_hit(user, target)` : Give the chance the user has to hit the target (after the move accuracy was tested).
- `proceed(user, target_bank, target_position)` : Execute the move.
- `move_usable_by_user(user, targets)` : Test if the user is able to use the move (not frozen etc...). This method invokes the `move_prevention_user` hook and is called before testing the move accuracy.
- `disabled?(user)` : Tell if the move cannot be choosen from the choice because it's disabled by an effect.
- `target_immune?(user, target)` : Test if the target is immune (type). This method can be overwritten to prevent effects like LeechSeed on Grass Pokémon. If this method returns true, the following message will be shown: `The {target} is not affected`.
- `move_blocked_by_target?(user, target)` : Test if the move is blocked by the target thanks to a specific effect (protect). This method calls the move_prevention_target hook and this hook should return true if the target blocks the move. This method doesn't prevent the move from working on other targets if they didn't block the move.
- `blocked_by?(target, symbol)` : Test if the target is blocking the move using a specific move described by symbol (the move db_symbol). This method should be used inside move_prevention_target hooks.
- `play_animation(user, targets)` : Plays the move animation.
- `deal_damage(user, actual_targets)` : Method responsive of dealing damage on each targets that was choosen and didn't evaded the move. Should return true to allow all the other `deal_` method to work.
- `effect_working?(user, actual_targets)` : Test if the effect is working (unless overwritten will always return true). If this method returns false, the deal_status, deal_stats and deal_effect method won't be called.
- `deal_status(user, actual_targets)` : Apply the status change on the targets
- `deal_stats(user, actual_targets)` : Apply the stat change on the targets
- `deal_effect(user, actual_targets)` : Apply the effect on the targets or terrain.

Example of move that was implemented with some of those methods and that is registered properly:

```ruby
module Battle
  class Move
    # Move that inflict attract effect to the ennemy
    class Attract < Move
      private

      # Ability preventing the move from working
      BLOCKING_ABILITY = %i[oblivious aroma_veil]
      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true if target.effects.has?(:attract) || (user.gender * target.gender) != 2

        if target.battle_item_db_symbol == :mental_herb
          @logic.item_change_handler.change_item(:none, true, target)
          return true
        elsif user.can_be_lowered_or_canceled?(BLOCKING_ABILITY.include?(target.ability_db_symbol))
          @scene.visual.show_ability(target)
          return true
        end

        return super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          target.effects.add(Effects::Attract.new(@logic, target, user))
          user.effects.add(Effects::Attract.new(@logic, user, target)) if target.battle_item_db_symbol == :destiny_knot
        end
      end
    end

    Move.register(:s_attract, Attract)
  end
end
```

### How to define an item that powers a move

There's two way to power move with items:
- Define a method that gives the multiplier depending on some criteria
- Define a specific type the item powers

For those way there's a method.

#### Item that powers move of certain type

Please note that it's not taking in account the definitive type of the move (normalize, electrify...).

Item affected by this:  `sea_incense`, `odd_incense`, `rock_incense`, `wave_incense`, `rose_incense`, `flame_plate`, `splash_plate`, `zap_plate`, `meadow_plate`, `icicle_plate`, `fist_plate `, `toxic_plate`, `earth_plate`, `sky_plate`, `mind_plate `, `insect_plate`, `stone_plate`, `spooky_plate`, `draco_plate`, `dread_plate`, `iron_plate `, `pixie_plat`.

Function to use: `Battle::Move.define_boosting_type_item(db_symbol, type)`

Example: `Battle::Move.define_boosting_type_item(:iron_plate, GameData::Types::STEEL)`

#### Item that powers a move on specific conditions

In order to specify the specific condition you will have to write a method in Battle::Move that takes the user and the target as parameter and returns a number.

Item affected by this: `muscle_band`, `wise_glasses`, `adamant_orb `, `lustrous_orb`, `griseous_orb`.

Function to use: `Battle::Move.define_boosting_item(db_symbol, method_sym)`

Example:
```ruby
module Battle
  class Move
    # Calc the Muscle Band multiplier
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_muscle_band_multiplier(user, target)
      physical? ? 1.1 : 1
    end
    define_boosting_item(:muscle_band, :calc_muscle_band_multiplier)
  end
end
```

### How to define user ability that powers a move

Some abilities are able to improve the power of the move, there's two way to define them:
- Using a method that calculate the multiplier
- Using a type when user is in bad condition

#### Ability that powers the user move in bad condition

Please note that it's not taking in account the definitive type of the move (normalize, electrify...).

Abilities affected by this: `blaze`, `overgrow`, `torrent`, `swarm`.

Function to use: `Battle::Move.define_boosting_type_ability(db_symbol, type)`

Example: `Battle::Move.define_boosting_type_ability(:swarm, GameData::Types::BUG)`

#### User ability that powers a move on specific condition

In order to specify the specific condition you will have to write a method in Battle::Move that takes the user and the target as parameter and returns a number.

Abilities affected by this: `rivalry`, `reckless`, `iron_fist`, `technician`, `pixilate`, `refrigerate`, `aerilate`, `galvanize`.

Function to use: `Battle::Move.define_boosting_ability(db_symbol, method_sym)`

Example:
```ruby
module Battle
  class Move
    # Technicien user ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_ua_technician(user, target)
      power <= 60 ? 1.5 : 1
    end
    define_boosting_ability(:technician, :calc_ua_technician)
  end
end
```

### How to define a target ability that deplete a move

Some abilities of the target are able to make a move less powerfull, to define them you should use the following function: `Battle::Move.define_depleting_ability(db_symbol, method_sym)`

List of abilities affected by this: `thick_fat`, `heatproof`, `dry_skin`.

Example: 
```ruby
module Battle
  class Move
    # Thick Fat foe ability multiplier
    # @param user [PFM::PokemonBattler]
    # @param target [PFM::PokemonBattler]
    # @return [Numeric]
    def calc_fa_thick_fat(user, target)
      THICK_FAT_TYPES.include?(type) ? 0.5 : 1
    end
    define_depleting_ability(:thick_fat, :calc_fa_thick_fat)
  end
end
```

Note: the multiplier is below 1 to deplete, meaning you can cover cases like dry_skin where the effect is the opposite, the move is powered if it is Fire type.


### How to define an Ability / Item that improve Attack / Spe Attack

In some case it is possible to improve the attack or spe attack statistic of a Pokemon when a move is used. To do so, you can define a method that takes user & target and that returns the factor applied to the statistic.

Here's the methods that helps you to define the abilities/items:
- Ability improving `atk`: `Battle::Move.define_ability_atk_modifier(db_symbol, method_sym)`
- Ability improving `ats`: `Battle::Move.define_ability_ats_modifier(db_symbol, method_sym)`
- Item improving `atk`: `Battle::Move.define_item_atk_modifier(db_symbol, method_sym)`
- Item improving `ats`: `Battle::Move.define_item_ats_modifier(db_symbol, method_sym)`

Note: this only applies to user ability / item !

List of abilities affected by this:
- atk => `pure_power`, `huge_power`, `flower_gif`, `guts`, `hustle`, `slow_start`
- ats => `solar_power`, `plus`, `minus`

List of items affected by this:
- atk => `choice_band`, `thick_club`
- ats => `choice_specs`, `soul_dew`, `deep_sea_tooth`

### How to define an Ability / Item that improve Defense / Spe Defense

In some case it is possible to improve the defense or spe defense statistic of a Pokemon when a move is used. To do so, you can define a method that takes user & target and that returns the factor applied to the statistic.

Here's the methods that helps you to define the abilities/items:
- Ability improving `dfe`: `Battle::Move.define_ability_dfe_modifier(db_symbol, method_sym)`
- Ability improving `dfs`: `Battle::Move.define_ability_dfs_modifier(db_symbol, method_sym)`
- Item improving `dfe`: `Battle::Move.define_item_dfe_modifier(db_symbol, method_sym)`
- Item improving `dfs`: `Battle::Move.define_item_dfs_modifier(db_symbol, method_sym)`

Note: this only applies to target ability / item !

List of abilities affected by this:
- dfe => `marvel_scale`
- dfs => `flower_gift`

List of items affected by this:
- dfe => `metal_powder`
- dfs => `metal_powder`, `deep_sea_scale`, `soul_dew`

### Things that are handled differently

- Ability `guts`: defined inside `calc_mod1_brn`
- Ability `infiltrator`: defined inside `calc_mod1_rl`
- Sunny & raining weather mods: defined inside `calc_mod1_sr`
- Ability `flash_fire`: defined inside `calc_mod1_ff`
- Item `life_orb`: defined inside `calc_mod2`
- Item `metronome`: defined inside `calc_mod2`
- Move rate of `me_first`: defined inside `calc_mod2`
- Ability `solid_rock` & `filter`: Stored inside `Battle::Move::SUPER_EFFECTIVE_REDUCTION` array and used into `calc_mod3`
- Item `expert_belt`: defined inside `calc_mod3`
- Item `tinted_lens`: defined inside `calc_mod3`
- Item `chilan_berry`: defined inside `calc_trb`
- Ability `magic_bounce`: defined inside `effect_working?`.
- Effect `magic_coat`: defined inside `effect_working?`.
- Ability `klutz` : defined inside `PFM::PokemonBattler#battle_item_db_symbol`.

Note: all of those definition will be improved in the futur.

### Define evasion & accuracy modifier

In some case it is possible to improve the accuracy or evasion of a Pokemon when a move is used. To do so, you can define a method that takes user & target and that returns the factor applied to the statistic.

Here's the methods that helps you to define the abilities/items:
- Ability improving `accuracy`: `Battle::Move.define_ability_accuracy_modifier(db_symbol, method_sym)`
- Ability improving `evasion`: `Battle::Move.define_ability_evasion_modifier(db_symbol, method_sym)`
- Item improving `accuracy`: `Battle::Move.define_item_accuracy_modifier(db_symbol, method_sym)`
- Item improving `evasion`: `Battle::Move.define_item_evasion_modifier(db_symbol, method_sym)`

Note: Evasion only applies to target and accuracy only applies to target

List of abilities affected by this:
- accuracy => `compoundeyes`, `hustle`
- evasion => `sand_veil`, `snow_cloak`, `tangled_feet`

List of items affected by this:
- accuracy => `wide_lens`, `zoom_lens`
- evasion => `brightpowder`, `lax_incense`

### Define type resistant berry

To define a type resistant berry you will use the following function:
```ruby
Battle::Move.define_type_resisting_berry(db_symbol, type, effectiveness)
```

Effectiveness can be set to one of the following values:
- `0` The berry check uneffective moves
- `1` The berry doesn't check effectiveness
- `2` The berry check super effective moves

Example:
```ruby
Battle::Move.define_type_resisting_berry(:babiri_berry, GameData::Types::STEEL, 2)
```
