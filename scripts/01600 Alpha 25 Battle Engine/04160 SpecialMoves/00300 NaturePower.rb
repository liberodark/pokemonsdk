module Battle
  class Move
    # When Nature Power is used it turns into a different move depending on the current battle terrain.
    # @see https://pokemondb.net/move/nature-power
    # @see https://bulbapedia.bulbagarden.net/wiki/Nature_Power_(move)
    # @see https://www.pokepedia.fr/Force_Nature
    class NaturePower < Move
      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return super || move_by_location(get_location).nil?
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        skill = GameData::Skill[move_by_location(get_location)]
        log_data("nature power # becomes #{skill.db_symbol}")

        move = Battle::Move[skill.be_method].new(skill.id, 1, 1, @scene)
        def move.usage_message(user)
          @scene.visual.hide_team_info
          scene.display_message_and_wait(parse_text(18, 127, '[VAR MOVE(0000)]' => name))
          PFM::Text.reset_variables
        end
        def move.move_usable_by_user(user, targets)
          return true
        end
        use_another_move(move, user)
      end

      # Return the current location type
      # @return [Symbol]
      def get_location
        $game_map.get_location($game_player.x, $game_player.y)
      end

      # Find the element using the given location
      # @param location [Symbol]
      # @return [object, nil]
      def move_by_location(location)
        moves_table[location]&.sample(random: logic.generic_rng)
      end

      # Moves by location type
      # @return [Hash<Symbol, Array<Symbol>]
      MOVES_TABLE_6G = {
        __undef__: %i[tri_attack],
        building: %i[tri_attack],
        grass: %i[energy_ball],
        desert: %i[earth_power],
        cave: %i[power_gem],
        water: %i[hydro_pump],
        shallow_water: %i[mud_bomb],
        snow: %i[frost_breath],
        icy_cave: %i[ice_beam],
        volcanic: %i[lava_plume],
        burial: %i[shadow_ball],
        soaring: %i[air_slash],
        misty_terrain: %i[moonblast],
        grassy_terrain: %i[energy_ball],
        electric_terrain: %i[thunderbolt],
        psychic_terrain: %i[psychic],
        space: %i[draco_meteor],
        ultra_space: %i[psyshock]
      }

      # Moves by location type
      # @return [Hash<Symbol, Array<Symbol>]
      def moves_table
        MOVES_TABLE_6G
      end
    end
    Move.register(:s_nature_power, NaturePower)
  end
end