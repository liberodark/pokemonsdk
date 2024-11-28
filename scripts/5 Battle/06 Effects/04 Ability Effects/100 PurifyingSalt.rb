module Battle
  module Effects
    class Ability
      class PurifyingSalt < Ability
        # A constant mapping status effects to their respective message IDs
        # @return [Hash{Symbol => Array<Integer>}]
        STATUS_MESSAGES = {
          burn: [19, 270],
          freeze: [19, 300],
          paralysis: [19, 285],
          poison: [19, 252],
          sleep: [19, 318],
          toxic: [19, 252]
        }

        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false if target != @target
          return false unless move&.status? && move.status_effects
          return false if move.status_effects.all? { |move_status| %i[flinch confusion cure].include?(move_status.status) }
          return false unless user&.can_be_lowered_or_canceled?

          move.scene.visual.show_ability(target)

          return true
        end

        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target != @target
          return if %i[flinch confusion cure].include?(status)
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target, true)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(*STATUS_MESSAGES[status], target))
            handler.scene.visual.hide_ability(target)
          end
        end

        # Give the move [Spe]atk mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_atk_multiplier(user, target, move)
          return 1 if target != @target
          return 1 unless move.type_ghost?

          log_data("Power halved due to : #{data_ability(db_symbol).name}")
          return 0.5
        end
      end

      register(:purifying_salt, PurifyingSalt)
    end
  end
end
