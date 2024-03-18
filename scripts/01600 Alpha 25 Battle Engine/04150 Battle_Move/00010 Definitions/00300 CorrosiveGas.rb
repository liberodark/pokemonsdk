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
        return false if targets.none? { |target| logic.item_change_handler.can_lose_item?(target, user) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless logic.item_change_handler.can_lose_item?(target, user)

          logic.item_change_handler.change_item(:none, false, target, user, self)
          # TODO: Add the corresponding text
        end
      end
    end

    Move.register(:s_corrosive_gas, CorrosiveGas)
  end
end
