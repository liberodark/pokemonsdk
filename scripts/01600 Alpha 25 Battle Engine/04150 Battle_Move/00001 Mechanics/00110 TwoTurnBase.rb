module Battle
  class Move
    class TwoTurnBase < Basic
      include Mechanics::TwoTurn

      private

      # List of move that can hit a Pokemon when he's out of reach
      #   CAN_HIT_BY_TYPE[oor_type] = [move db_symbol list]
      CAN_HIT_BY_TYPE = [
        %i[spikes toxic_spikes stealth_rock], # Phantom Force & Shadow Force
        %i[earthquake fissure magnitude spikes toxic_spikes stealth_rock], # Dig
        %i[gust gravity whirlwind thunder swift sky_uppercut twister smack_down hurricane thousand_arrows spikes toxic_spikes stealth_rock], # Fly & Bounce
        %i[surf whirlpool spikes toxic_spikes stealth_rock], # Dive
        nil # Others moves
      ]

      # Out of reach moves to type
      #   OutOfReach[sb_symbol] => oor_type
      TYPES = { dig: 1, fly: 2, dive: 3, bounce: 2, phantom_force: 0, shadow_force: 0 }

      # Return the list of the moves that can reach the pokemon event in out_of_reach, nil if all attack reach the user
      # @return [Array<Symbol>]
      def can_hit_moves
        return CAN_HIT_BY_TYPE[TYPES[db_symbol] || 4]
      end

      # List all the text_id used to announce the waiting turn in TwoTurnBase moves
      ANNOUNCES = {
        bounce: [19, 544],
        dig: [19, 538],
        dive: [19, 535],
        freeze_shock: [59, 866],
        geomancy: [19, 1213],
        ice_burn: [19, 869],
        meteor_beam: [59, 2014],
        phantom_force: [19, 541],
        razor_wind: [19, 547],
        shadow_force: [19, 541],
        sky_attack: [19, 550],
        skull_bash: [19, 556],
        solar_beam: [19, 553],
        fly: [19, 529]

        # TODO: Add the corresponding text for Electro Shot
      }

      # Move db_symbol to a list of stat and power
      # @return [Hash<Symbol, Array<Array[Symbol, Power]>]
      MOVE_TO_STAT = {
        electro_shot: [[:ats, 1]],
        meteor_beam: [[:ats, 1]],
        skull_bash: [[:dfe, 1]]
      }

      # Move db_symbol to a list of stat and power change on the user
      # @return [Hash<Symbol, Array<Array[Symbol, Power]>]
      def stat_changes_turn1(user, targets)
        return MOVE_TO_STAT[db_symbol]
      end

      # Display the message and the animation of the turn
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      def proceed_message_turn1(user, targets)
        file_id, text_id = ANNOUNCES[db_symbol]
        return unless file_id && text_id

        @scene.display_message_and_wait(parse_text_with_pokemon(file_id, text_id, user))
      end
    end

    Move.register(:s_2turns, TwoTurnBase)
  end
end
