# Safe Eval Command

> Tom is a genius.  
> _~Scott_

For long, RPG Maker XP based its custom commands on `eval`, for commoner, it's called `Script Command`. For this kind of command you have to know `Ruby` (or guess and complain it crashes).

This has a great advantage, you can do pretty much anything. This also has a great disadvantage, they can do pretty much anything.

Alternatively, this cause a lot of side effects, sometimes due to bug in CRuby: [Fix memory leak of rb_ast_t in parser](https://bugs.ruby-lang.org/projects/ruby-master/repository/git/revisions/d22dfce1cc5e5425e062dc7883b522ef85fe06db). This side effect forced PSDK team to implement a pretty nasty fix: [Implement eval killer to fix one of the memory leak causing the game to freeze on long play](https://gitlab.com/pokemonsdk/pokemonsdk/-/commit/713ab9d8454ddb877a167c41d6132cc3cc6f84d7)

In this document, we're going to explore a solution that does not involve `eval` and that can handled with Pokémon Studio without having to know a syntax.

## What operations do we need?

Lets dissect some of the script commands we see on Pokémon Workshop.

Basic check:
```ruby
trainer_spotted?(7)
```

Adding a complex Pokemon:
```ruby
ajouter_pokemon_param(
  id: :mudkip, given_name: $trainer.name, level: 10, memo_text: [69, 0], no_shiny: true, 
  captured_with: 797, nature: :hardy, moves: [:tackle, :growl, :water_gun, :mud_slap], stats: [20, 20, 20, 20, 20, 20], 
  gender: %w[f m i][gv[495]]
)
```

Starting a custom battle:
```ruby
bi = Battle::Logic::BattleInfo.new
bi.vs_type = 2
bi.add_party(0, *bi.player_basic_info)
party = []
party << PFM::Pokemon.generate_from_hash(id: :sandslash, level: 25, form: 2, item: :iron_berry, gender:1, nature: 
:modest, moves: [:magnitude, nil, nil, nil])
bi.add_wild_pokemon(1, party, 7)
bi.battle_id = 11
$scene.setup_start_battle(Battle::Scene, bi)
```

As you can see, script command are anywhere between dead simple to complex asf.

Fortunately, the two later could be dedicated command in Pokémon Studio, regardless let's use them to guess what kind of operation we do need.

### Method invocation

The very first command we see is very basic, we invoke a method with a simple parameter `trainer_spotted?(7)`.

A simple way to describe it in object notation would be:
```js
{
  operation: 'invoke',
  method: 'trainer_spotted?',
  arguments: [7],
}
```

With that we defined invocation of very simple methods.

### Method invocation with keyword arguments and pre-computed objects

The second example is much more complex. We're building a Pokemon with some predefined attributes, and some that is partially computed (gender and given_name).

This mean we need to be able to use several operations, to do so we will use an Array to describe the whole expression. Of course, for the pre-computed object we will need a way to store their result and reuse them.

Here's a proposal of the translation of `Adding a complex Pokemon`:
```js
[
  {
    operation: 'set',
    name: 'genders',
    value: [{ string: 'f' }, { string: 'm' }, { string: 'i' }]
  },
  {
    operation: 'set',
    name: 'genderIndex',
    value: {
      operation: 'invoke',
      method: '[]',
      self: '$game_variables',
      arguments: [495]
    }
  },
  {
    operation: 'set',
    name: 'gender',
    value: {
      operation: 'invoke',
      method: '[]',
      self: 'genders',
      arguments: [{ variable: 'genderIndex' }]
    }
  },
  {
    operation: 'set',
    name: 'given_name',
    value: {
      operation: 'getAttribute',
      self: '$trainer',
      name: 'name'
    }
  },
  {
    operation: 'invoke',
    method: 'ajouter_pokemon_param',
    keyword_arguments: {
      id: 'mudkip',
      given_name: { variable: 'given_name' },
      level: 10,
      memo_text: [69, 0],
      no_shiny: true,
      captured_with: 797,
      nature: 'hardy',
      moves: ['tackle', 'growl', 'water_gun', 'mud_slap'],
      stats: [20, 20, 20, 20, 20, 20],
      gender: { variable: 'gender' }
    }
  }
]
```

This structure supposedly give the same result but extract the sub operations away from the keyword arguments.

### Complex chain of commands

As you can see with the `Starting a custom battle` example, script commands could perform very complex chain of operation. Those chain of operation can be translated to object notation but we need to think about the different way to get data and different data kind.

```js
[
  {
    operation: 'set',
    name: 'bi',
    value: {
      operation: 'invoke',
      method: 'new',
      self: 'Battle::Logic::BattleInfo'
    }
  },
  {
    operation: 'setAttribute',
    name: 'vs_type',
    self: 'bi',
    value: 2
  },
  {
    operation: 'set',
    name: 'trainer_info',
    value: {
      operation: 'invoke',
      method: 'player_basic_info',
      self: 'bi'
    }
  },
  {
    operation: 'invoke',
    method: 'add_party',
    self: 'bi',
    arguments: [0],
    splat_argument: 'trainer_info',
  },
  {
    operation: 'set',
    name: 'party',
    value: []
  },
  {
    operation: 'set',
    name: 'sandslash',
    value: {
      operation: 'invoke',
      method: 'generate_from_hash',
      self: 'PFM::Pokemon',
      keyword_arguments: {
        id: 'sandslash',
        level: 25,
        form: 2,
        item: 'iron_berry',
        gender: 1, 
        nature: 'modest',
        moves: ['magnitude', null, null, null]
      }
    }
  },
  {
    operation: 'invoke',
    method: '<<',
    self: 'party',
    arguments: [{ variable: 'sandslash' }]
  },
  {
    operation: 'invoke',
    method: 'add_wild_pokemon',
    self: 'bi',
    arguments: [1, { variable: 'party' }, 7]
  },
  {
    operation: 'setAttribute',
    name: 'battle_id',
    self: 'bi',
    value: 11
  },
  {
    operation: 'invoke',
    method: 'setup_start_battle',
    self: '$scene',
    arguments: [
      { constant: 'Battle::Scene' },
      { variable: 'bi' }
    ]
  }
]
```

### List of operations

As you could see, we did not actually need a lot of operation to replicate the script commands we worked with. We can be pretty confident on the following list of operations:

- `set`: Set a variable to a value => `{name} = {value}`
- `setAttribute`: Set an attribute to a value => `{self}.{name} = {value}`
- `getAttribute`: Get an attribute to use it as value => `{self}.{name}`
- `invoke`: Call a method => `[{self}.]{method}(<arguments, *splat_argument, **keyword_arguments>)`
- `digAttribute`: Get an attribute from a complex path: `{self}<attributePath>`

## Specifications

### Value

Values are direct values from the Object representation with several specificities:

1. Invoke operation are only permitted for the `set` command
2. Get/Dig attribute operation are only permitted for the `set` command
3. Strings are converted to ruby symbols
4. Ruby string are noted this way: `{ string: 'value' }`
5. Variables are accessed this way: `{ variable: 'name' }`
6. Constants are accessed this way: `{ constant: 'ConstantPath::From::Object' }`
7. `null` is converted to ruby `nil`

### Constants

Constant cannot all be accessed. There will be a list of allowed constants, all the ruby native constant won't be part of this list to avoid undesired invocation.

The interpreter will have to check that the constant were actually defined in the classes using `.const_defined?(name, false)`

### Invocation

Invocation only permit the use of public methods (even for Interpreter itself).

The `invoke` operation has the following optional attributes:

- `arguments`: Array of values to be used as argument.
- `splat_argument`: Name of the local variable to use as splat argument
- `keyword_arguments`: List of keyword arguments associating keys to values.
- `self`: variable that get its method invoked. Supports local, global and instance variables.

### Set operation

The set operation assign a value to a variable. Its argument name supports local, global and instance variables. Its value support Invoke operation, get/dig attribute operation and other value types.

### Set attribute operation

The set attribute operation is a digest version of `invoke`, it essentially only take a single value.

Here's two operation that does the same:
```js
[
  {
    operation: 'setAttribute',
    self: 'bi',
    name: 'battle_id',
    value: 11
  },
  {
    operation: 'invoke',
    self: 'bi',
    method: 'battle_id=',
    arguments: [11]
  }
]
```

### Get attribute operation

The get attribute operation is also a digest version of `invoke`, it essentially access an attribute value that takes no arguments.

Here's two operation that does the same:
```js
[
  {
    operation: 'set',
    name: 'given_name',
    value: {
      operation: 'getAttribute',
      self: '$trainer',
      name: 'name' 
    }
  },
  {
    operation: 'set',
    name: 'given_name',
    value: {
      operation: 'invoke',
      self: '$trainer',
      method: 'name' 
    }
  }
]
```

As you can see this is not very interesting but it gives a good parallel for the `setAttribute` operation.

### Dig attribute operation

This operation aim to explore a complex path of attributes. For example: `scene.logic.bank_effects[bank]`.

It's being supported by the `set` operation. If you have to call a method from the attribute path you have to assign it to a local variable and then invoke the method using that local variable as self.

Here's a translation of the example:

```js
[
  {
    operation: 'set',
    name: 'bank_effects',
    value: {
      operation: 'digAttribute',
      self: 'scene',
      path: ['logic', 'bank_effects', [{ variable: bank }]]
    }
  }
]
```

As you can see, the path supports two kind of values, symbol, or array. The array values acts as indexing an let you reference any value that isn't an operation as index (it is translated to `public_send(:[], *values)`).

Note: All the attributes must be public otherwise dig attribute cannot get the attribute value!

## Implementation

The implementation must fall under `Interpreter`. Ideally `Studio2PSDK` converts the json objects to actual ruby object which are able to execute the command through interpreter. Those can be stored into `Data/EventCommands/<map_id>.rxdata` and all have a unique key.

The interpreter itself can run the commands by detecting them with this way:
1. Is command starting with `#safe:` ?
2. Ditch additional lines and strip resulting string.
3. Take whats behind `#safe:` as value key.
4. Run the commands for that key.

Of course, when a map is loaded, its command should be loaded.

Note: Data might be stored otherwise depending on specification given by Pokémon Studio.