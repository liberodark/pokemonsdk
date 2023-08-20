module Battle
  module Effects
    class Ability
      class NeutralizingGas < Ability
        # Create a new Neutralizing Gas effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          if who != with && who == @target && @activated
            handler.scene.display_message_and_wait(parse_text(60, 408))
            retrieve_abilities(handler, who, with)
            @activated = false
          end

          suppress_abilities(handler, who, with)
          if with == @target
            handler.scene.visual.show_ability(@target)
            handler.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text(60, 407))
            @activated = true
          end
        end

        # If Neutralizing Gas is currently activated by this pokemon
        # @return [Boolean]
        def activated?
          return @activated
        end
        alias activated activated?

        private

        # Suppress the ability of each battlers except the user if the conditions are fullfilled
        # @param handler [Battle::Logic::SwitchHandler]
        def suppress_abilities(handler, who, with)
          battlers = handler.logic.all_alive_battlers.reject { |battler| battler == @target }
          battlers.each do |battler|
            next if battler.effects.has?(:ability_suppressed) || battler.has_ability?(:neutralizing_gas)
            next unless handler.logic.ability_change_handler.can_change_ability?(battler, :none)

            battler.effects.add(Effects::AbilitySuppressed.new(@logic, battler))
          end
        end

        # Retrieve the ability of each battlers except the user if the conditions are fullfilled
        # @param handler [Battle::Logic::SwitchHandler]
        def retrieve_abilities(handler, who, with)
          battlers = handler.logic.all_alive_battlers.reject { |battler| battler == @target || battler == with }
          return if battlers.any? { |battler| battler.has_ability?(:neutralizing_gas) }

          battlers.each do |battler|
            next unless battler.effects.has?(:ability_suppressed)

            battler.effects.get(:ability_suppressed).kill
            battler.effects.delete_specific_dead_effect(:ability_suppressed)
            battler.ability_effect.on_switch_event(handler, battler, battler)
          end
        end
      end
      register(:neutralizing_gas, NeutralizingGas)
    end
  end
end
