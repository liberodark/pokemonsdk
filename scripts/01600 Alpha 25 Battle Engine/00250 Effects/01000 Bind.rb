module Battle
  module Effects
    # Class that describe the bind effect
    class Bind < PokemonTiedEffectBase
      # Hash giving the message info based on the db_symbol of the move
      MESSAGE_INFO = {
        bind: [806, true],
        wrap: [813, true],
        fire_spin: [830, false],
        clamp: [820, true],
        whirlpool: [827, false],
        sand_tomb: [836, false],
        magma_storm: [833, false],
        infestation: [1234, false]
      }

      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param origin [PFM::PokemonBattler] Pokemon that used the move dealing this effect
      # @param turn_count [Integer]
      # @param move [Battle::Move] move responsive of the effect
      def initialize(logic, pokemon, origin, turn_count, move)
        super(logic, pokemon)
        @origin = origin
        @move = move
        self.counter = turn_count
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        scene.display_message(message)
        logic.damage_handler.damage_change((@pokemon.max_hp / hp_factor).clamp(1, Float::INFINITY), @pokemon)
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill)
        return handler.prevent_change do
          scene.display_message(message)
        end
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :bind
      end

      private

      # Get the message text
      # @return [String]
      def message
        message_id, two_pokemon_message = (MESSAGE_INFO[@move.db_symbol] || [0, false])
        return parse_text_with_2pokemon(19, message_id, @pokemon, @origin) if two_pokemon_message

        return parse_text_with_pokemon(19, message_id, @pokemon)
      end

      # Get the HP factor delt by the move
      # @return [Integer]
      def hp_factor
        return @origin.hold_item?(:binding_band) ? 8 : 6
      end
    end
  end
end
