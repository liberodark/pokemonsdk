module Battle
  module Effects
    class Ability
      class GoodAsGold < Ability
        # Returns a list of moves that fail when targeting Good as Gold
        # @return [Array<Symbol>]
        MOVES_AFFECTED = %i[memento curse strength_sap]
        # Function called when we try to use a move as the user (returns :prevent if user fails)
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        # @return [:prevent, nil] :prevent if the move cannot continue
        def on_move_prevention_user(user, targets, move)
          return if user == @target || !targets.include?(@target)
          return unless MOVES_AFFECTED.include?(move)

          move.show_usage_failure(user)
          return :prevent
        end

        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is evading the move
        def on_move_prevention_target(user, target, move)
          return false if user == @target || target != @target
          return false unless move&.status?
          return false unless move&.one_target?

          @logic.scene.visual.show_ability(target)
          @logic.scene.visual.wait_for_animation
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 210, target))

          return true
        end
      end
      register(:good_as_gold, GoodAsGold)
    end
  end
end
