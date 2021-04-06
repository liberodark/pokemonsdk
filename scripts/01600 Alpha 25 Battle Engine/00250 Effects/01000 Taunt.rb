module Battle
  module Effects
    # Implement the Taunt effect
    class Taunt < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param move [Battle::Move] move that is disabled
      def initialize(logic, pokemon)
        super(logic, pokemon)
        self.counter = 3
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        message = parse_text_with_pokemon(19, 574, @pokemon)
        @logic.scene.display_message_and_wait(message)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :taunt
      end
    end
  end
end
