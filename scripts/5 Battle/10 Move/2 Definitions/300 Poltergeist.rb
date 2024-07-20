module Battle
  class Move
    # Implements the Poltergeist move
    class Poltergeist < Basic
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.none? { |target| target.hold_item?(target.battle_item_db_symbol) }

        return true
      end

      # Function which permit things to happen before the move's animation
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] expected targets
      def post_accuracy_check_move(user, actual_targets)
        actual_targets.each do |target|
          @scene.display_message_and_wait(parse_text_with_pokemon(66, 1470, target, PFM::Text::ITEM2[1] => data_item(target.battle_item_db_symbol).name))
        end
      end
    end

    Move.register(:s_poltergeist, Poltergeist)
  end
end