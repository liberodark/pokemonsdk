module Battle
  class Move
    # Opponent is unable to use moves that the user also knows.
    class Imprison < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if user.effects.has?(:imprison)
        return show_usage_failure(user) && false unless has_common_moves?(user, targets)

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:imprison)

          user.effects.add(Effects::Imprison.new(logic, user))
          scene.display_message_and_wait(deal_message(user, target))
        end
      end

      # Message displayed when the effect is dealt
      # @param user [PFM::PokemonBattler]
      # @param actual_targets [Array<PFM::PokemonBattler>]
      # @return [String]
      def deal_message(user, actual_targets)
        return parse_text_with_pokemon(19, 586, user)
      end

      # Checks if the user and any target have common moves
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] potential targets
      # @return [Boolean] true if there are common moves, false otherwise
      def has_common_moves?(user, targets)
        user_move_db_symbols = user.moveset.map(&:db_symbol)

        return targets.any? do |target|
          target_move_db_symbols = target.moveset.map(&:db_symbol)
          (user_move_db_symbols.intersection(target_move_db_symbols)).any?
        end
      end
    end

    Move.register(:s_imprison, Imprison)
  end
end