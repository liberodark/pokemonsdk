module Battle
  module Effects
    class Ability
      class IceFace < Ability
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if who == with
          return if who != @target
          return if who.form == 0
          return unless $env.hail?

          who.form_calibrate(:base)
        end

        # Function called when a damage_prevention is checked
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, Integer, nil] :prevent if the damage cannot be applied, Integer if the hp variable should be updated
        def on_damage_prevention(handler, hp, target, launcher, skill)
          return if target != @target || launcher == @target
          return if target.form != 0
          return unless skill&.physical?
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
            handler.scene.visual.wait_for_animation
            target.form_calibrate(:battle)
            handler.scene.visual.show_switch_form_animation(target)
          end
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          return unless weather_type == :hail
          return if @target.form == 0

          handler.scene.visual.show_ability(@target)
          handler.scene.visual.wait_for_animation
          @target.form_calibrate(:base)
          handler.scene.visual.show_switch_form_animation(@target)
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target != @target
          return if target.form == 0

          target.form_calibrate(:base)
        end
      end

      register(:ice_face, IceFace)
    end
  end
end
