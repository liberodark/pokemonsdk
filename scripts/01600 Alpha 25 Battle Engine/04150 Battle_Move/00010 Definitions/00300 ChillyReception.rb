module Battle
  class Move
    # Chilly Reception sets the hail/snow, then the user switches out of battle.
    class ChillyReception < Move
      # Tell if the move is a move that switch the user if that hit
      def self_user_switch?
        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        nb_turn = user.hold_item?(:icy_rock) ? 8 : 5
        logic.weather_change_handler.weather_change_with_process(:hail, nb_turn)
        return false unless @logic.switch_handler.can_switch?(user, self)

        @logic.switch_request << { who: user }
      end
    end
    Move.register(:s_chilly_reception, ChillyReception)
  end
end
