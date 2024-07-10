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

        # Give the move [Spe]atk mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_atk_multiplier(user, target, move)
          return 1 if user.bank != @target.bank

          return move.physical? && $env.sunny? ? 1.5 : 1
        end

        # Give the move [Spe]def mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_def_multiplier(user, target, move)
          return 1 if target.bank != @target.bank
          return 1 unless user.can_be_lowered_or_canceled?

          return move.special? && ($env.sunny? || $env.hardsun?) ? 1.5 : 1
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
      end
      register(:flower_gift, FlowerGift)
    end
  end
end
