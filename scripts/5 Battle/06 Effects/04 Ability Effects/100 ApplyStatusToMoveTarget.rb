module Battle
  module Effects
    class Ability
      class ApplyStatusToMoveTarget < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if launcher != @target || launcher == target || launcher.dead?
          return unless status_appliable?(handler, hp, launcher, target, skill)

          handler.scene.visual.show_ability(launcher)
          handler.logic.status_change_handler.status_change_with_process(status, target)
          display_message(handler, hp, target, launcher, skill)
        end

        # Check if conditions to apply status are valid
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def status_appliable?(handler, hp, launcher, target, skill)
          raise 'This method should be implemented in the subclass'
        end

        # Return the status to apply
        # @return [Symbol]
        def status
          raise 'This method should be implemented in the subclass'
        end

        # Get the message text
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [String, nil]
        def display_message(handler, hp, target, launcher, skill)
          return nil
        end

        # Number between 0 & 1 telling how much chance we have
        # @return [Float]
        def rate
          return 0.3
        end
      end

      class PoisonTouch < ApplyStatusToMoveTarget
        # Check if conditions to apply status are valid
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def status_appliable?(handler, _, launcher, target, skill)
          return false unless skill&.direct?
          return false unless target.can_be_poisoned?
          return false unless bchance?(rate, handler.logic)

          return true
        end

        # Return the status to apply
        # @return [Symbol]
        def status
          return :poison
        end

        # Get the message text
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [String, nil]
        def display_message(handler, _, target, _, _)
          return handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 472, target))
        end
      end

      class ToxicChain < ApplyStatusToMoveTarget
        # Check if conditions to apply status are valid
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def status_appliable?(handler, _, _, target, skill)
          return false unless skill
          return false unless target.can_be_poisoned?
          return false unless bchance?(rate, handler.logic)

          return true
        end

        # Return the status to apply
        # @return [Symbol]
        def status
          return :toxic
        end
      end

      register(:poison_touch, PoisonTouch)
      register(:toxic_chain, ToxicChain)
    end
  end
end
