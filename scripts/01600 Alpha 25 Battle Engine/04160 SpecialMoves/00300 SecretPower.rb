module Battle
  class Move
    # Secret Power deals damage and has a 30% chance of inducing a secondary effect on the opponent, depending on the environment.
    # @see https://pokemondb.net/move/secret-power
    # @see https://bulbapedia.bulbagarden.net/wiki/Secret_Power_(move)
    # @see https://www.pokepedia.fr/Force_Cach%C3%A9e
    class SecretPower < BasicWithSuccessfulEffect
      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return super || power_by_location(get_location).nil?
      end

      private

      # Play the move animation
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      def play_animation(user, targets)
        @secret_power = power_by_location(get_location) # Already tested as not nil
        mock_id = GameData::Skill.get_id(@secret_power.mock) if @secret_power.mock.is_a?(Symbol)
        mock = Move.new(mock_id, 1, 1, @scene)
        mock.send(:play_animation, user, targets)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return if logic.generic_rng.rand(100) > proc_chance
        actual_targets.each do |target|
          self.send(@secret_power.type, user, target, *@secret_power.params)
        end
      end

      # Change the target status
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param status [Symbol]
      def sp_status(user, target, status)
        logic.status_change_handler.status_change_with_process(status, target, user, self)
      end

      # Change a stat
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param stat [Symbol]
      # @param power [Integer]
      def sp_stat(user, target, stat, power)
        logic.stat_change_handler.stat_change_with_process(stat, power, target, user, self)
      end

      # Return the current location type
      # @return [Symbol]
      def get_location
        $game_map.get_location($game_player.x, $game_player.y)
      end

      # Find the element using the given location
      # @param location [Symbol]
      # @return [object, nil]
      def power_by_location(location)
        secret_power_table[location]&.sample(random: logic.generic_rng)
      end
      
      # Secret Power Card to pick
      class SPC
        attr_reader :mock, :type, :params
        # Create a new Secret Power possibility
        # @param mock [Symbol, Integer] ID or db_symbol of the animation move
        # @param type [Symbol] name of the function to call
        # @param params [Array<Object>] params to pass to the function
        def initialize(mock, type, *params)
          @mock, @type, @params = mock, type, params
        end
        def to_s
          "<SPC @mock=:#{@mock} @type=:#{@type} @params=#{@params}>"
        end
      end

      # Status by location type
      # @return [Hash<Symbol, Array<SPC>]
      SECRET_POWER_TABLE_6G = {
        __undef__: [SPC.new(:body_slam, :sp_status, :paralysis)],
        building: [SPC.new(:body_slam, :sp_status, :paralysis)],
        grass: [SPC.new(:vine_whip, :sp_status, :sleep)],
        desert: [SPC.new(:"mud-slap", :sp_stat, :acc, -1)],
        cave: [SPC.new(:rock_throw, :sp_status, :flinch)],
        water: [SPC.new(:water_pulse, :sp_stat, :atk, -1)],
        shallow_water: [SPC.new(:mud_shot, :sp_stat, :spd, -1)],
        snow: [SPC.new(:avalanche, :sp_status, :freezing)],
        icy_cave: [SPC.new(:ice_shard, :sp_status, :freezing)],
        volcanic: [SPC.new(:incinerate, :sp_status, :burn)],
        burial: [SPC.new(:shadow_sneak, :sp_status, :flinch)],
        soaring: [SPC.new(:gust, :sp_stat, :spd, -1)],
        misty_terrain: [SPC.new(:fairy_wind, :sp_stat, :ats, -1)],
        grassy_terrain: [SPC.new(:vine_whip, :sp_status, :sleep)],
        electric_terrain: [SPC.new(:thunder_shock, :sp_status, :paralysis)],
        psychic_terrain: [SPC.new(:confusion, :sp_stat, :spd, -1)],
        space: [],
        ultra_space: []
      }

      # Moves by location type
      # @return [Hash<Symbol, Array<Symbol>]
      def secret_power_table
        SECRET_POWER_TABLE_6G
      end

      # Chances of status/stat to proc out of 100
      # @return [Integer]
      def proc_chance
        30
      end
    end
    Move.register(:s_secret_power, SecretPower)
  end
end