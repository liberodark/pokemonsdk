module Battle
  module Effects
    class Ability
      class PurifyingSalt < Ability
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target != @target
          return if status == :cure
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
            handler.scene.visual.wait_for_animation
            # Add the corresponding text
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
