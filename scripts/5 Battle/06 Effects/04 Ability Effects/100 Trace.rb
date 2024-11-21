module Battle
  module Effects
    class Ability
      # Class managing Trace ability
      class Trace < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target

          potential_givers = handler.logic.foes_of(with).select { |giver| handler.logic.ability_change_handler.can_change_ability?(with, giver) }
          return if potential_givers.empty?

          giver = potential_givers.sample(random: handler.logic.generic_rng)
          handler.logic.ability_change_handler.apply_ability_change(with, giver.battle_ability_db_symbol, giver) do
            post_ability_change_message(with, giver)
          end
        end

        # Get the post ability change message
        # @param receiver [PFM::PokemonBattler] Ability receiver
        # @param giver [PFM::PokemonBattler] Potential ability giver
        # @return [String]
        def post_ability_change_message(receiver, giver)
          return parse_text_with_pokemon(19, 381, giver, PFM::Text::ABILITY[1] => giver.ability_name)
        end
      end

      register(:trace, Trace)
    end
  end
end
