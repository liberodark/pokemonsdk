module Battle
  module Effects
    class Ability
      class Prankster < Ability
        # Function called when we try to check if the effect changes the definitive priority of the move
        # @param user [PFM::PokemonBattler]
        # @param priority [Integer]
        # @param move [Battle::Move]
        # @return [Proc, nil]
        def on_move_priority_change(user, priority, move)
          return nil if user != @target
          return nil unless move.status?

          return priority + 1
        end
      end
      register(:prankster, Prankster)
    end
  end
end
