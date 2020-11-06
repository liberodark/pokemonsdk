module Battle
  module Effects
    # Class describing all the effect ("abstract") and helping the handler to manage effect
    class EffectBase
      # Create a new effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      def initialize(logic)
        @logic = logic
        # Counter so we can disable the effect
        # @type [Integer]
        @counter = Float::INFINITY
      end

      # Function that sets the counter
      # @param counter [Integer] new counter value
      def counter=(counter)
        @counter = counter.clamp(0, Float::INFINITY)
      end

      # Function that updates the counter of the effect
      def update_counter
        @counter -= 1
      end

      # Function telling if the effect should be removed from effects handler
      # @return [Boolean]
      def dead?
        @counter <= 0
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :base
      end

      # Kill the effect (in order to remove it from the effects handler)
      def kill
        @counter = -1
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        return nil
      end

      # Function called when a stat_increase_prevention is checked
      # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
      # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the stat increase cannot apply
      def on_stat_increase_prevention(handler, stat, target, launcher, skill)
        nil && handler && stat && target && launcher && skill
      end

      # Function called when a stat_decrease_prevention is checked
      # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
      # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the stat decrease cannot apply
      def on_stat_decrease_prevention(handler, stat, target, launcher, skill)
        nil && handler && stat && target && launcher && skill
      end

      # Function called when a stat_change is about to be applied
      # @param handler [Battle::Logic::StatChangeHandler]
      # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
      # @param power [Integer] power of the stat change
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [Integer, nil] if integer, it will change the power
      def on_stat_change(handler, stat, power, target, launcher, skill)
        nil && handler && stat && target && launcher && skill
      end

      # Function called when a pre_item_change is checked
      # @param handler [Battle::Logic::ItemChangeHandler]
      # @param db_symbol [Symbol] Symbol ID of the item
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the item change cannot be applied
      def on_pre_item_change(handler, db_symbol, target, launcher, skill)
        nil && handler && db_symbol && target && launcher && skill
      end

      # Function called when a post_item_change is checked
      # @param handler [Battle::Logic::ItemChangeHandler]
      # @param db_symbol [Symbol] Symbol ID of the item
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the item change cannot be applied
      def on_post_item_change(handler, db_symbol, target, launcher, skill)
        nil && handler && db_symbol && target && launcher && skill
      end

      # Function called when a status_prevention is checked
      # @param handler [Battle::Logic::StatusChangeHandler]
      # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, nil] :prevent if the status cannot be applied
      def on_status_prevention(handler, status, target, launcher, skill)
        nil && handler && status && target && launcher && skill
      end

      # Function called when a post_status_change is performed
      # @param handler [Battle::Logic::StatusChangeHandler]
      # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_status_change(handler, status, target, launcher, skill)
        nil && handler && status && target && launcher
      end

      # Function called when a damage_prevention is checked
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
      def on_damage_prevention(handler, hp, target, launcher, skill)
        nil && handler && hp && target && launcher && skill
      end

      # Function called after damages were applied (post_damage, when target is still alive)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage(handler, hp, target, launcher, skill)
        nil && handler && hp && target && launcher && skill
      end

      # Function called after damages were applied and when target died (post_damage_death)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage_death(handler, hp, target, launcher, skill)
        nil && handler && hp && target && launcher && skill
      end

      # Function called when testing if pokemon can switch regardless of the prevension.
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @return [:passthrough, nil] if :passthrough, can_switch? will return true without checking switch_prevention
      def on_switch_passthrough(handler, pokemon, skill)
        nil && handler && pokemon && skill
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill)
        nil && handler && pokemon && skill
      end

      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(handler, who, with)
        nil && handler && who && with
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        nil && logic && scene && battlers
      end

      # Function called when a weather_prevention is checked
      # @param handler [Battle::Logic::WeatherChangeHandler]
      # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      # @return [:prevent, nil] :prevent if the status cannot be applied
      def on_weather_prevention(handler, weather_type, last_weather)
        nil && handler && weather_type && last_weather
      end

      # Function called after the weather was changed (post_weather_change)
      # @param handler [Battle::Logic::WeatherChangeHandler]
      # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
      def on_post_weather_change(handler, weather_type, last_weather)
        nil && handler && weather_type && last_weather
      end

      # Function called when we try to use a move as the user (returns :prevent if user fails)
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @param move [Battle::Move]
      # @return [:prevent, nil] :prevent if the move cannot continue
      def on_move_prevention_user(user, targets, move)
        nil && user && targets && move
      end

      # Function called when we try to check if the target evades the move
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      # @return [Boolean] if the target is evading the move
      def on_move_prevention_target(user, target, move)
        nil && user && target && move
      end

      # Function called when we try to get the definitive type of a move
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler] expected target
      # @param move [Battle::Move]
      # @param type [Integer] current type of the move (potentially after effects)
      # @return [Integer, nil] new type of the move
      def on_move_type_change(user, target, move, type)
        nil && user && target && move && type
      end
    end
  end
end
