module Battle
  class Move
    # Class managing Triple Arrows move
    # We do not use effect_working because the attack must reduce the opponent's defensive stats
    # Even if we already have the critical hit rate increase activated.
    class TripleArrows < Basic
      # @return [Array<Symbol>]
      UNSTACKABLE_EFFECTS = %i[dragon_cheer focus_energy triple_arrows]

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do
          next if UNSTACKABLE_EFFECTS.any? { |effect_name| user.effects.has?(effect_name) }

          user.effects.add(Effects::TripleArrows.new(logic, user, turn_count))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1047, user))
        end
      end

      private

      # Return the turn countdown before the effect proc (including the current one)
      # @return [Integer]
      def turn_count
        return 4
      end
    end

    Move.register(:s_triple_arrows, TripleArrows)
  end
end
