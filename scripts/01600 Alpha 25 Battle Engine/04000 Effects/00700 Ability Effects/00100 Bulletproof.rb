module Battle
  module Effects
    class Ability
      class Bulletproof < Ability
        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false if target != @target
          return @logic.scene.visual.show_ability(target) && true if move.ballistics? && user.can_be_lowered_or_canceled?

          return false
        end
      end
      register(:bulletproof, Bulletproof)
    end
  end
end
