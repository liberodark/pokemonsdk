module Battle
  module Effects
    class Item
      class SafetyGoggles < Item
        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is evading the move
        def on_move_prevention_target(user, target, move)
          return if target != @target

          return move.powder?
        end
      end

      register(:safety_goggles, SafetyGoggles)
    end
  end
end
