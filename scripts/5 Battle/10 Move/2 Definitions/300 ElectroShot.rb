module Battle
  class Move
    # The user gathers electricity on the first turn, boosting its Sp. Atk stat, then fires a high-voltage shot on the next turn. The shot will be fired immediately in rain.
    class ElectroShot < TwoTurnBase
      # Check if the two turn move is executed in one turn
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Boolean]
      def shortcut?(user, targets)
        return true if $env.rain? || $env.hardrain?

        super
      end
    end
    Move.register(:s_electro_shot, ElectroShot)
  end
end
