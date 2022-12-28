module Battle
  class Move
    # Class describing a move that drains HP
    class StrengthSap < Move
      private
      
      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          atkdrained = user.hold_item?(:big_root) ? target.atk * 130 / 100 : target.atk
          if target.has_ability?(:liquid_ooze)
            @scene.visual.show_ability(target)
            logic.damage_handler.damage_change(atkdrained, user)
            @scene.display_message_and_wait(parse_text_with_pokemon(19, 457, user))
          else
            logic.damage_handler.heal(user, atkdrained)
          end
        end
        return true
      end
      
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return show_usage_failure(user) && false if targets.all? do |target|
          (target.atk_stage == -6 && !target.effects.has?(:contrary)) || (target.atk_stage == 6 && target.effects.has?(:contrary))
        end

        return show_usage_failure(user) && false unless super
        return true
      end
      
      # Tell that the move is a drain move
      # @return [Boolean]
      def drain?
        return true
      end
    end
    
    Move.register(:s_strength_sap, StrengthSap)
  end
end
