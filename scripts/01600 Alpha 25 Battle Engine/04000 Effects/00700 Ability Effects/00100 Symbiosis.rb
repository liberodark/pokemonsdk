module Battle
  module Effects
    class Ability
      class Symbiosis < Ability
        # List of moves that cause the talent to proceed after the target has taken damage
        DEFERRED_MOVES = %i[fling natural_gift]
        # List of methods that make the target invalid
        INVALID_BE_METHOD = %i[s_knock_off s_thief]
        # Create a new Symbiosis effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super

          @post_damage_activation = false
          @affect_allies = true
          @ally = nil
        end

        # Function called when a pre_item_change is checked
        # @param handler [Battle::Logic::ItemChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the item
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the item change cannot be applied
        def on_pre_item_change(handler, db_symbol, target, launcher, skill)
          return unless handler.logic.allies_of(@target).include?(target)

          @ally = target
          @post_damage_activation = should_activate?(@ally, skill)
        end

        # Function called when a post_item_change is checked
        # @param handler [Battle::Logic::ItemChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the item
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_item_change(handler, db_symbol, target, launcher, skill)
          return if @post_damage_activation
          return unless valid_target?(handler, @ally, skill)

          if handler.logic.item_change_handler.can_give_item?(@target, @ally)
            handler.scene.visual.show_ability(@target)
            handler.logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 1219, @target, PFM::Text::PKNICK[2] => @ally.name,
                                                                                            PFM::Text::ITEM2[1] => @target.item_name))

            transfer_item(handler, @ally)
          end
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return unless @post_damage_activation
          return unless valid_target?(handler, @ally, skill)

          @post_damage_activation = false
          if handler.logic.item_change_handler.can_give_item?(@target, @ally)
            handler.scene.visual.show_ability(@target)
            handler.logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 1219, @target, PFM::Text::PKNICK[2] => @ally.name,
                                                                                            PFM::Text::ITEM2[1] => @target.item_name))

            transfer_item(handler, @ally)
          end
        end

        private

        # Check if we can give our object to the target that just lost it
        # @param handler [Battle::Logic::DamageHandler]
        # @param ally [PFM::PokemonBattler]
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def valid_target?(handler, ally, skill)
          return false unless handler.logic.allies_of(@target).include?(ally)
          return false if handler.logic.switch_request.any? { |request| request[:who] == ally }
          return false if skill && INVALID_BE_METHOD.include?(skill.be_method)
          return false if ally.effects.has?(:item_burnt)

          return true
        end

        # Check if the object should be given after the target turn
        # @param ally [PFM::PokemonBattler]
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def should_activate?(ally, skill)
          return true if @target.battle_item_db_symbol.to_s.include?("_gem")
          return true if skill && DEFERRED_MOVES.include?(skill.db_symbol)
          return true if ally.item_effect.is_a?(Battle::Effects::Item::TypeResistingBerry)

          return false
        end

        # Method that gives the item
        # @param handler [Battle::Logic::DamageHandler]
        # @param ally [PFM::PokemonBattler]
        def transfer_item(handler, ally)
          new_item = @target.battle_item_db_symbol
          handler.logic.item_change_handler.change_item(:none, true, @target)
          handler.logic.item_change_handler.change_item(new_item, true, ally, @target)
        end
      end

      register(:symbiosis, Symbiosis)
    end
  end
end
