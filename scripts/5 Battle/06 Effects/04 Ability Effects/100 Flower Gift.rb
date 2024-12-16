module Battle
  module Effects
    class Ability
      class FlowerGift < Ability
        # Create a new FlowerGift effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          original_form = @target.form
          return unless @target.form_generation(-1) != original_form

          handler.scene.visual.show_ability(@target)
          handler.scene.visual.show_switch_form_animation(@target)
        end

        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 1 unless $env.sunny? || $env.hardsun?

          return 1.5
        end

        # Give the dfs modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfs_modifier
          action = @logic.current_action
          return 1 unless $env.sunny? || $env.hardsun?
          return 1 if action.is_a?(Actions::Attack) && !action.launcher.can_be_lowered_or_canceled?

          return 1.5
        end
      end

      register(:flower_gift, FlowerGift)
    end
  end
end
