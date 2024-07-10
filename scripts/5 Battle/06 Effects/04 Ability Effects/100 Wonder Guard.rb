module Battle
  module Effects
    class Ability
      class WonderGuard < Ability
        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false if target != @target
          return false if move.db_symbol == :struggle

          @logic.scene.visual.show_ability(@target) if blocked?(user, move, target)
          return blocked?(user, move, target)
        end

        # Function called when we try to check if the move is blocked by Wonder Guard
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def blocked?(user, move, target)
          return false if move.status?

          return move.type_modifier(user, target) <= 1 && user.can_be_lowered_or_canceled?
        end
      end
      register(:wonder_guard, WonderGuard)
    end
  end
end
