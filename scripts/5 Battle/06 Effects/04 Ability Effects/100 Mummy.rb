module Battle
  module Effects
    class Ability
      # Class managing Mummy ability
      class Mummy < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless skill&.direct? && launcher&.alive? && !launcher.has_ability?(:long_reach)
          return if launcher.ability_effect.is_a?(Battle::Effects::Ability::Mummy)
          return unless handler.logic.ability_change_handler.can_change_ability?(launcher)

          handler.scene.visual.show_ability(target, true)
          handler.logic.ability_change_handler.apply_ability_change(launcher, target.battle_ability_db_symbol, target) do
            post_ability_change_message(launcher, target)
          end
          handler.scene.visual.hide_ability(target)
        end
        alias on_post_damage_death on_post_damage

        # Get the post ability change message
        # @param receiver [PFM::PokemonBattler] Ability receiver
        # @param giver [PFM::PokemonBattler] Potential ability giver
        # @return [String]
        def post_ability_change_message(receiver, giver)
          return parse_text_with_pokemon(19, 463, receiver)
        end
      end

      # Class managing Lingering Aroma ability
      class LingeringAroma < Mummy
        # Get the post ability change message
        # @param receiver [PFM::PokemonBattler] Ability receiver
        # @param giver [PFM::PokemonBattler] Potential ability giver
        # @return [String]
        def post_ability_change_message(receiver, giver)
          return parse_text_with_pokemon(66, 1610, receiver)
        end
      end
      register(:mummy, Mummy)
      register(:lingering_aroma, LingeringAroma)
    end
  end
end
