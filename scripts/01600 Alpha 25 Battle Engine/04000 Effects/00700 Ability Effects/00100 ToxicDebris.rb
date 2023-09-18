module Battle
  module Effects
    class Ability
      class ToxicDebris < Ability
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == @target
          return unless skill&.physical?

          # @type [Effects::ToxicSpikes]
          effect = @logic.bank_effects[launcher.bank]&.get(:toxic_spikes)
          return if effect && effect.power >= 2

          effect.empower if effect
          handler.logic.add_bank_effect(Effects::ToxicSpikes.new(handler.logic, launcher.bank)) unless effect

          handler.scene.visual.show_ability(target)
          handler.scene.visual.wait_for_animation
          handler.scene.display_message_and_wait(parse_text(18, launcher.bank == 0 ? 158 : 159))
        end
      end
      register(:toxic_debris, ToxicDebris)
    end
  end
end
