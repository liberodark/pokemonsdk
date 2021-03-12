module Battle
  module Effects
    # Class that describe the bind effect
    class Bind < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param origin [PFM::PokemonBattler] Pokemon that used the move dealing this effect
      # @param turn_count [Integer]
      def initialize(logic, pokemon, origin, turn_count)
        super(logic, pokemon)
        @origin = origin
        self.counter = turn_count
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        scene.display_message(parse_text_with_2pokemon(19, message_id, @pokemon, @origin))
        logic.damage_handler.damage_change((@pokemon.max_hp / hp_factor).clamp(1, Float::INFINITY), @pokemon)
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill)
        return handler.prevent_change do
          scene.display_message(parse_text_with_2pokemon(19, message_id, @pokemon, @origin))
        end
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :bind
      end

      private

      # Get the message id to display the effect
      # @return [Integer]
      def message_id
        return 806
      end

      # Get the HP factor delt by the move
      # @return [Integer]
      def hp_factor
        return 16
      end
    end
  end
end
