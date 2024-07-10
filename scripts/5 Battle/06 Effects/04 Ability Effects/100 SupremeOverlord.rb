module Battle
  module Effects
    class Ability
      class SupremeOverlord < Ability
        # Create a new SupremeOverlord effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @multiplier = 0
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          return if handler.logic.trainer_battlers.all?(&:alive?)
          
          handler.logic.trainer_battlers.each { |battler| @multiplier += battler.ko_count }
          @multiplier = @multiplier.clamp(0, 5)
          @multiplier = (@multiplier / 10.0).truncate(1)
          log_data("Supreme Overlord - Power of moves increased by #{1 + @multiplier}")

          handler.scene.visual.show_ability(with)
          handler.scene.visual.wait_for_animation
          #TODO: Add the corresponding text
        end

        # Give the move base power mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def base_power_multiplier(user, target, move)
          return super unless user == @target

          return super + @multiplier
        end
      end
      register(:supreme_overlord, SupremeOverlord)
    end
  end
end
