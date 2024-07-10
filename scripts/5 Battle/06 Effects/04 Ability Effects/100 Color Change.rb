module Battle
  module Effects
    class Ability
      class ColorChange < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target
          return unless skill && launcher
          return if skill.status? || skill.is_a?(Battle::Move::Basic::MultiHit) && !skill.last_hit?
          definitive_types = skill.definitive_types(launcher, target)
          return if definitive_types.any? { |type| target.type?(type) || type == 0}
          return if launcher.has_ability?(:sheer_force) && launcher.ability_effect&.activated?

          handler.scene.visual.show_ability(target)
          target.type1 = definitive_types.first
          target.type2 = 0
          target.type3 = 0
          text = parse_text_with_pokemon(19, 899, target, PFM::Text::PKNICK[0] => target.given_name,
                                                          '[VAR TYPE(0001)]' => data_type(definitive_types.first).name)
          handler.scene.display_message_and_wait(text)
        end
      end
      register(:color_change, ColorChange)
    end
  end
end
