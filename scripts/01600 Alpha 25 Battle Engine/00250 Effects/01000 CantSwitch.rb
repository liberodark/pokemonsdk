module Battle
  module Effects
    # CantSwitch Effect
    class CantSwitch < PokemonTiedEffectBase
      # The Pokemon that launched the attack
      # @return [PFM::PokemonBattler]
      attr_reader :origin
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param origin [PFM::PokemonBattler] Pokemon that used the move dealing this effect
      # @param move [Battle::Move] move responsive of the effect
      def initialize(logic, pokemon, origin, move)
        super(logic, pokemon)
        @origin = origin
        @move = move
      end

      # Function called when testing if pokemon can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param pokemon [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, pokemon, skill)
        return if pokemon != @pokemon

        return handler.prevent_change do
          handler.scene.display_message_and_wait(message)
        end
      end

      # Tell if the effect is dead
      # @return [Boolean]
      def dead?
        super || !@origin.position
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :cantswitch
      end

      private

      # Get the message text
      # @return [String]
      def message
        message_id = @pokemon.bank == 0 ? 878 : (@logic.battle_info.trainer_battle? ? 880 : 879)

        return parse_text_with_pokemon(19, message_id, @pokemon)
      end
    end
  end
end
