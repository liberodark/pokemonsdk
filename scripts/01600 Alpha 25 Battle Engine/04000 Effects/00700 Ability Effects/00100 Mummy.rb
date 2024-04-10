module Battle
  module Effects
    class Ability
      class Mummy < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless skill&.direct? && launcher && launcher.hp > 0 && !launcher.has_ability?(:long_reach)
          return if launcher.ability_effect == target.ability_effect
          return unless handler.logic.ability_change_handler.can_change_ability?(launcher, db_symbol)

          handler.scene.visual.show_ability(target)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 405, launcher, PFM::Text::ABILITY[1] => target.ability_name)) # Needs Gen IX texts adaptation
          handler.logic.ability_change_handler.change_ability(launcher, db_symbol)
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          on_post_damage(handler, hp, target, launcher, skill)
        end
      end
      register(:mummy, Mummy)
      register(:lingering_aroma, Mummy)
    end
  end
end
