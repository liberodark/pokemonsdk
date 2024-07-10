module Battle
  class Move
    class CourtChange < Move
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        target = logic.foes_of(user).first
        logic.switch_bank_effects(user.bank, target.bank)
        # TODO: Add the corresponding text
      end
    end

    Move.register(:s_court_change, CourtChange)
  end
end
