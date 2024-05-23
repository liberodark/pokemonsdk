module Battle
  module Effects
    class Ability
      class Disguise < Ability
        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @target || target.form != 0 || target.effects.has?(:substitute)
          return if skill.nil? || skill.status?
          return unless launcher&.can_be_lowered_or_canceled?

          hp = (target.max_hp / 8).clamp(1, target.hp)

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
            handler.logic.damage_handler.damage_change(hp, target)
            handler.scene.display_message_and_wait(parse_text(60, 364))
            target.form_calibrate(:battle)
            handler.scene.visual.show_switch_form_animation(target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(59, 1910, target))
            reset_types(target)
          end
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target != @target || target.form == 0

          target.form_calibrate(:base)
        end

        private

        # Recovers its original types
        # @param target [PFM::PokemonBattler]
        def reset_types(target)
          target.type1 = data_type(target.data.type1).id
          target.type2 = data_type(target.data.type2).id
          target.type3 = 0
        end
      end

      register(:disguise, Disguise)
    end
  end
end
