module Battle
  module Effects
    class Ability
      class MoldBreaker < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return unless with == @target

          handler.scene.visual.show_ability(with)
          message = parse_text_with_pokemon(file_id, text_id, with)
          handler.scene.display_message_and_wait(message)
        end

        # Function called when we try to use a move as the user (returns :prevent if user fails)
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        # @return [:prevent, nil] :prevent if the move cannot continue
        def on_move_prevention_user(user, targets, move)
          return if user != @target

          user.ability_used = false
        end

        private

        # ID of the text file for the on-switch message.
        # @return [Integer]
        def file_id
          return 19
        end

        # ID of the text in the file for the on-switch message.
        # @return [Integer]
        def text_id
          return 442
        end
      end

      class Teravolt < MoldBreaker
        def text_id
          return 502
        end
      end

      class Turboblaze < MoldBreaker
        def text_id
          return 505
        end
      end

      register(:mold_breaker, MoldBreaker)
      register(:teravolt, Teravolt)
      register(:turboblaze, Turboblaze)
    end
  end
end
