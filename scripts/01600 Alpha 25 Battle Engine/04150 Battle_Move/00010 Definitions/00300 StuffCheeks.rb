module Battle
  class Move
    # Stuff Cheeks move
    class StuffCheeks < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false unless user.hold_berry?(user.battle_item_db_symbol)

        return true
      end

      # Get the reason why the move is disabled
      # @param user [PFM::PokemonBattler] user of the move
      # @return [#call] Block that should be called when the move is disabled
      def disable_reason(user)
        return proc { @logic.scene.display_message_and_wait(parse_text_with_pokemon(60, 508, user)) } unless user.hold_berry?(user.battle_item_db_symbol)

        return super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.hold_berry?(target.battle_item_db_symbol)

          if target.item_effect.is_a?(Effects::Item::Berry)
            # @type [Effects::Item::Berry]
            target.item_effect.execute_berry_effect(force_heal: true, force_execution: true)
            if target.has_ability?(:cheek_pouch) && !target.effects.has?(:heal_block)
              @scene.visual.show_ability(target)
              @logic.damage_handler.heal(target, target.max_hp / 3)
            end
            scene.logic.stat_change_handler.stat_change_with_process(:dfe, 2, target, user, self)

          end

          @logic.item_change_handler.change_item(:none, true, target, user, self)
        end
      end
    end
    Move.register(:s_stuff_cheeks, StuffCheeks)
  end
end
