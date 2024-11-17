# Create a Status With Script

In this tutorial, you'll learn how to create your own statuses and code their effects into the Battle Engine.
Please note that this tutorial only works starting from PSDK .26.34 and Studio 2.4.0. Make sure your project is up-to-date!

## Before coding

To create your effects, you need to ensure you are using the same name whenever you are refering to it. Choose a good name and keep to it.
Then, in Studio, go to each and every move that should be able to inflict your custom status, and apply your status as a status effect for these moves.

When it's done, PSDK will parse the jsons files and verify whether any of your moves inflict an official status, or a custom one. Please note that when Studio saves your custom status inside a json, it will append `Custom_` before the status' name. If you were to create a status named `Groggy`, then Studio will name it `Custom_Groggy`. If PSDK detects a name starting by `Custom_`, it will downcase the name and transform it into a symbol. In this case, `Custom_Groggy` becomes :custom_groggy, and you'll need to remember this one for the rest of the tutorial.

## Defining an ID for our status

As the title suggest, you'll need to ensure PSDK has a way to refer to your custom status, and we do so using an ID. To do that, open the `states.json` file which you can find in `Data/configs` using your preferred IDE (VSCode is the recommended choice).

Then, at the end of the `{ }`, add a comma, then write the name of your custom status, followed by an ID of your choice. Here's an example:
```json
{
    "klass": "Configs::States",
    "ids": {
        "poison": 1,
        "paralysis": 2,
        "burn": 3,
        "sleep": 4,
        "freeze": 5,
        "confusion": 6,
        "toxic": 8,
        "death": 9,
        "ko": 9,
        "flinch": 7,
        "custom_groggy": 20 // This one is the one we added
    }
}
```
Warning: To ensure future compatibility in case of Game Freak adding new statuses, you should try to book an ID a bit higher than the current ones already booked. In the example above, you can see I booked ID 20. It's not a actual minimum, but you get the idea.

Make sure to save the file, and then PSDK will reload the corresponding .rxdata file.

## Defining the status in the code

### Defining the status for a Pokémon

Pokémon can be inflicted with your status, and PSDK (and you when you'll write your code) needs to know if it's the case or not. Currently, the PFM::Pokemon class already made a series of methods available for use, such as these:
```ruby
    # Is the Pokemon paralyzed?
    # @return [Boolean]
    def paralyzed?
      return @status == Configs.states.ids[:paralysis]
    end

    # Paralyze the Pokemon
    # @param forcing [Boolean] force the new status
    # @return [Boolean] if the pokemon has been paralyzed
    def status_paralyze(forcing = false)
      if (@status == 0 || forcing) && !dead?
        @status = Configs.states.ids[:paralysis]
        return true
      end
      return false
    end

    # Can the Pokemon be paralyzed?
    # @return [Boolean]
    def can_be_paralyzed?
      return false if @status != 0
      return false if type_electric?

      return true
    end
```

These methods are the only three needed to ensure a Pokémon can still work correctly. Let's explain these three:
- `def paralyzed?` returns a Boolean which tells you if the Pokémon suffers from paralysis. If this is the case, it'll return `true`, else `false`.
- `def status_paralyze(forcing = false)` allows you and parts of the code to inflict a Pokémon with paralysis. If `true` is given as the parameter, then the infliction is forced, otherwise it's depending on specific conditions.
- `def can_be_paralyzed?` tells you whether or not the Pokémon can be paralyzed, depending again on specific conditions. Returns `true` if yes, otherwise `false`.

Now that we explained these methods, you need to create the same ones for your project. You'll need to create a custom script and paste this code template in it. /!\ This is only a template, which means you have things to change to fit your project!!!
Note: if you don't know how to create a custom script, you should have a look at the .md file available in any Technical Demo created using Pokémon Studio, available in the scripts folder at the root of the project!

```ruby
module PFM
  class Pokemon
    # Is the Pokemon custom statused?
    # @return [Boolean]
    def custom_statused? # Change this name
      return @status == Configs.states.ids[:custom_status_db] # Change this symbol
    end

    # Custom statused the Pokemon
    # @param forcing [Boolean] force the new status
    # @return [Boolean] if the pokemon has been custom_statused
    def status_custom_status(forcing = false) # Change this name
      if (@status == 0 || forcing) && !dead?
        @status = Configs.states.ids[:custom_status_db] # Change this symbol
        return true
      end
      return false
    end

    # Can the Pokemon be paralyzed?
    # @return [Boolean]
    def can_be_custom_statused?
      return false if @status != 0
      # return false if condition (add conditions as you see fit, one line at a time)

      return true
    end
  end
end
```
Make sure to change any and every line where "Change this" appear!

### Define the status for the StatusChangeHandler (BattleEngine)

As you may or may not know, statuses in battle can or cannot be applied depending on a ton of factors. The StatusChangeHandler is responsible for checking these factors, and apply the status if needed. There a few things to make in this part of the tutorial, so stay focused.

First, we need to tell the StatusChangeHandler which method to call to apply our status to a Pokémon. To do that, create a new custom script and add this code to it:
```ruby
module Battle
  class Logic
    # Handler responsive of answering properly status changes requests
    class StatusChangeHandler < ChangeHandlerBase
      STATUS_APPLY_METHODS[:custom_status_db] = :status_custom_status
    end
  end
end
```
Again, you'll need to modify two things here:
- :custom_status_db should be modified to your status' symbol, so `:custom_groggy` for example
- :status_custom_status should be modified to the name of the method that applies your status and created above, so `:status_custom_groggy` for example

Once you've done that, you can tell the StatusChangeHandler which messages should appear when the status is applied. This part isn't mandatory, but it's recommended you do so.
For that, add a line break then paste this: 
```ruby
      # List of message ID when applying a status
      STATUS_APPLY_MESSAGE[:custom_status_db] = line
      # List of animation ID when applying a status
      STATUS_APPLY_ANIMATION[:custom_status_db] = id
```
The first assignation tells the system that the status application text is located at the line "line" in the CSV 100019. You'll need to add a new line text for this specific file inside Pokémon Studio (DON'T TRY TO EDIT IT WITHOUT STUDIO).
The second assignation tells the system that the status application animation ID is "id". Only make this assignation if you are SURE you have an animation ready, else **don't**.

Now, we need to tell the StatusChangeHandler of the application conditions. To do that, you need to copy and paste this code **after the end corresponding to `class StatusChangeHandler`**. If you don't, it won't work. Here's the code and an example of how it should look:
```ruby
    # Cannot be paralyzed
    StatusChangeHandler.register_status_prevention_hook('My Custom Status: custom_status') do |handler, status, target, _, skill| #Change "custom_status"
      next if status != :custom_status_db || target.can_be_custom_statused? #Change :custom_status_db and can_be_custom_statused

      next handler.prevent_change do
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 285, target)) if skill.nil? || skill.status? #Change 285 here
      end
    end
```
The example: 
```ruby
module Battle
  class Logic
    # Handler responsive of answering properly status changes requests
    class StatusChangeHandler < ChangeHandlerBase
      # Your custom code here
    end

    # Cannot be paralyzed
    StatusChangeHandler.register_status_prevention_hook('My Custom Status: custom_status') do |handler, status, target, _, skill| #Change "custom_status"
      next if status != :custom_status_db || target.can_be_custom_statused? #Change :custom_status_db and can_be_custom_statused?

      next handler.prevent_change do
        handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 285, target)) if skill.nil? || skill.status? #Change 285 here
      end
    end
  end
end
```
Here, you also need to change a few things:
- Change the `custom_status` in `'My Custom Status: custom_status'`
- Change the `:custom_status_db` and the `can_be_custom_statused?` (you should be used to it by now)
- Change the 285 to the line of your prevention text you created in the 100019.csv file (with Studio also)

We're done with the StatusChangeHandler, let's get to the next part!

### Defining the status for the CatchHandler (BattleEngine)

In the mainline games, statuses can give a boost to the calculation of a Pokémon's catchrate. If your custom status also gives such a bonus, then follow this part.

First, as with the chapters above, create a custom script and copy/paste this code inside:

```ruby
module Battle
  class Logic
    # Handler responsive of answering properly Pokemon catching requests
    class CatchHandler < ChangeHandlerBase
      STATUS_MODIFIER[:custom_status_db] = 1 #Change :custom_status_db and the 1
    end
  end
end
```
This one is quite easy:
- Change the :custom_status_db
- Change the 1 to any **positive** (minimum 0) float value you want to apply as the multiplier. Yes, you could technically apply 0.5 and have your status reduce the catchrate. Go crazy with this info! :D

It's done for the CatchHandler, let's now see how to create a proper Status Effect!

### Defining the status as an Effect (BattleEngine)

Before actually creating an Effect, we need to add a method to the Parent class of every Status Effect.

To do that, create a custom script, then copy/paste this code:
```ruby
module Battle
  module Effects
    class Status < EffectBase
      # Tell if the status effect is custom_status (REPLACE THIS custom_status)
      # @return [Boolean]
      def custom_status? # Change the name
        @status == :custom_status_db # Change the :custom_status_db
      end
    end
  end
end
```
You'll need to make 3 changes:
- Change the custom_status in the comments
- Change the name of the method
- Change the `:custom_status_db`

Once you've done that, we can now create our own Status Effect!

To do that, create a new custom script (or reuse this one, but make sure to now overwrite it and paste this next code after everything you pasted earlier):
```ruby
module Battle
  module Effects
    class Status
      class CustomStatus < Status # Replace CustomStatus
        # Prevent custom_status from being applied twice
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target != self.target
          return if status != :custom_status_db # Change :custom_status_db

          return handler.prevent_change do
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 282, target)) # Change 282
          end
        end

        # Function giving the name of the effect
        # @return [Symbol]
        def name
          :custom_status_db # Change :custom_status_db
        end
      end

      register(:custom_status_db, CustomStatus) # Change :custom_status_db and CustomStatus
    end
  end
end
```
Here, you have multiple things to change across multiple lines. Make sure that you are still consistent with the names you have setup all along:
- Change `CustomStatus`. Make sure to use a clear name. Example with our "Groggy" from earlier: `CustomGroggy` or just `Groggy`. In case of a status that uses several words, make sure to write it in Pascal Case. Example: `MyVeryOwnStatusClassWithUpcase`.
- Change `:custom_status_db`
- Change 282 by the line in the CSV 100019 for the prevention message (add it with Studio as well)

Congrats, you have created your own Status Effect! 🥳
Of course, this just means that your status will not be properly recognized by the system, and you'll know have somewhere to code all your weird interactions! I won't be going into the details of how to create such interactions, but you can have a look at any and every classes that have the Status class as its Parent class (search `< Status` with VSCode), or any class that has the EffectBase class as its Parent class (search `< EffectBase` with VSCode). From now on, only your imagination's and your Ruby skills are the limit! 

## Afterwords

Thank you for reading this tutorial! We've seen how to create a status and make it available in different part of the code, we created messages to display in battle, and we created a Status Effect for our custom status! 

If you followed this tutorial thoroughly and made every needed changes, then your custom status should work out of the box! If it does not, make sure to create a #support post on the Discord, and make sure to document what you did and post your code in the topic! The community will be happy to help! :D

Have fun customizing your statuses, maker! 🚀