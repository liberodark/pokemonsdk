module Battle
  module Effects
    class Status
      class Asleep < Status
        # List of moves that works when the user is asleep
        SLEEPING_MOVES = %i[snore sleep_talk]

        # Prevent sleep from being applied twice
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          # Ignore if status is not asleep or the taget is not the target of this effect
          return if target != @target
          return if status != :sleep

          # Prevent change by telling the target is already asleep
          return handler.prevent_change do
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 315, target))
          end
        end

        # Function called when we try to use a move as the user (returns :prevent if user fails)
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        # @return [:prevent, nil] :prevent if the move cannot continue
        def on_move_prevention_user(user, targets, move)
          return if user != @target

          # We check if the user is still asleep during this turn
          return user.sleep_check ? handle_sleep_prevention(user, move) : handle_wakeup(user, move)
        end

        # Function giving the name of the effect
        # @return [Symbol]
        def name
          return :sleep
        end

        private

        # Function to handle move prevention when the user is the target and is asleep
        # @param user [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [:prevent]
        def handle_sleep_prevention(user, move)
          move.scene.visual.show_rmxp_animation(user, 469 + status_id)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 309, user))
          # If it's a sleeping move we don't prevent user from using the move
          return if SLEEPING_MOVES.include?(move.db_symbol)

          return :prevent
        end

        # Function to handle waking up the Pokémon
        # @param user [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [nil]
        def handle_wakeup(user, move)
          move.scene.visual.refresh_info_bar(user)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 312, user))

          remove_nightmare_effect(user)

          return nil
        end

        # Function to remove the Nightmare effect from the Pokémon
        # @param user [PFM::PokemonBattler]
        def remove_nightmare_effect(user)
          user.effects.get(:nightmare)&.kill
          user.effects.delete_specific_dead_effect(:nightmare)
        end
      end

      register(:sleep, Asleep)
    end
  end
end
