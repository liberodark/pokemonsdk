module Battle
  class Move
    # Glaive Rush doubles the damage taken during the same turn and the turn after.
    class GlaiveRush < Basic
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.effects.add(Effects::GlaiveRush.new(logic, user))
      end
    end

    Move.register(:s_glaive_rush, GlaiveRush)
  end
end
