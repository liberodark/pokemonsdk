module Battle
  class Move
    # Class describing a move taking two turn to execute
    class TwoTurn < Basic
      # List all the text_id used to announce the waiting turn in TwoTurn moves
      ANNOUNCES = {
        dig: 538, fly: 529, dive: 535, bounce: 544,
        phantom_force: 541, shadow_force: 541, solar_beam: 553,
        skull_bash: 556, razor_wind: 547, freeze_shock: 866,
        ice_burn: 869, geomancy: 1213, sky_attack: 550,
        focus_punch: 1213
      }
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        # Cancel effect from previous use
        user.effects.get(:out_of_reach)&.kill
        user.effects.deleted_dead_effects
        return false unless super
        return true if user.effects.has?(:forced_next_move)
        return true if db_symbol == :solar_beam && $env.sunny?

        if user.hold_item?(:power_herb)
          @logic.item_change_handler.change_item(:none, true, user)
          return true
        end

        user.effects.add(Effects::ForcedNextMove.new(@logic, user, self, targets))
        oor_type = Effects::OutOfReach::TYPES[db_symbol]
        user.effects.add(Effects::OutOfReach.new(@logic, user, oor_type)) if oor_type
        id_txt = ANNOUNCES[db_symbol]
        @scene.display_message_and_wait(parse_text_with_pokemon(19, id_txt, user)) if id_txt
        # TODO: please make a subclass for that specific move and link it in the DB!
        @logic.stat_change_handler.stat_change_with_process(:dfe, 1, user) if db_symbol == :skull_bash
        return false
      end

      # Return the actual base power of the move
      # @return [Integer]
      def power
        # TODO: please make a subclass for that specific move and link it in the DB!
        return super / 2 if db_symbol == :solar_beam && ($env.sandstorm? || $env.hail? || $env.rain?)

        return super
      end
    end

    Move.register(:s_2turns, TwoTurn)
  end
end
