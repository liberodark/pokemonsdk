module Battle
  module Effects
    class Ability
      # Class managing Power of Alchemy / Receiver abilities
      class PowerOfAlchemy < Ability
        # Create a new PowerOfAlchemy effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target == @target
          return unless handler.logic.ability_change_handler.can_change_ability?(@target, target)

          handler.logic.ability_change_handler.apply_ability_change(@target, target.battle_ability_db_symbol, target) do
            post_ability_change_message(@target, target)
          end
        end

        # Get the post ability change message
        # @param receiver [PFM::PokemonBattler] Ability receiver
        # @param giver [PFM::PokemonBattler] Potential ability giver
        # @return [String]
        # @note The following error is for French only
        def post_ability_change_message(receiver, giver)
          # TODO: In the CSV, remove “[VAR PKNICK(0000)]” and put it at the beginning instead of “Le Pokémon”.
          return parse_text_with_pokemon(59, 1902, receiver, PFM::Text::ABILITY[1] => giver.ability_name)
        end
      end

      register(:power_of_alchemy, PowerOfAlchemy)
      register(:receiver, PowerOfAlchemy)
    end
  end
end
