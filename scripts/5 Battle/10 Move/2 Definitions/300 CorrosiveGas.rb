module Battle
  class Move
    class CorrosiveGas < Move
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.none? { |target| @logic.item_change_handler.can_lose_item?(target, user) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless @logic.item_change_handler.can_lose_item?(target, user)

          @scene.display_message_and_wait(parse_text_with_2pokemon(59, 2022, user, target, PFM::Text::ITEM2[2] => target.item_name))
          @logic.item_change_handler.change_item(:none, false, target, user, self)
        end
      end
    end

    Move.register(:s_corrosive_gas, CorrosiveGas)
  end
end
