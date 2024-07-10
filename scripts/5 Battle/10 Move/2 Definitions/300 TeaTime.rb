module Battle
  class Move
    # Teatime move
    class Teatime < Move
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return @scene.display_message_and_wait(parse_text(18, 106)) && false if actual_targets.none? { |target| target.hold_berry?(target.battle_item_db_symbol) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        @scene.display_message_and_wait(parse_text(60, 404))
        actual_targets.each do |target|
          next unless target.hold_berry?(target.battle_item_db_symbol)

          if target.item_effect.is_a?(Effects::Item::Berry)
            # @type [Effects::Item::Berry]
            target_effect = Effects::Item.new(logic, target, target.item_effect.db_symbol)
            target_effect.execute_berry_effect(force_heal: true, force_execution: true)
            if target.has_ability?(:cheek_pouch) && !target.effects.has?(:heal_block)
              @scene.visual.show_ability(target)
              @logic.damage_handler.heal(target, target.max_hp / 3)
            end
          end
        end
      end
    end
    Move.register(:s_teatime, Teatime)
  end
end
