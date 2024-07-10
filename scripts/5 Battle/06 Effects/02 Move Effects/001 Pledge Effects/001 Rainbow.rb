module Battle
  module Effects
    class Rainbow < PositionTiedEffectBase
      # Create a new Rainbow effect (Water Pledge + Fire Pledge)
      # @param logic [Battle::Logic]
      # @param bank [Integer] bank where the effect acts
      def initialize(logic, bank)
        super(logic, bank, 0)
        self.counter = 4
        effect_creation_text
      end

      # Give the effect chance modifier given to the Pokémon with this effect
      # @param move [Battle::Move::Basic] the move the chance modifier will be applied to
      # @return [Float, Integer] multiplier
      def effect_chance_modifier(move)
        return move.status_effects.any? { |move_status| move_status.status == :flinch } ? 1 : 2
      end

      # Display the message associated with the effect's creation
      def effect_creation_text
        @logic.scene.display_message_and_wait(parse_text(18, 170 + bank.clamp(0, 1)))
      end

      # Method called when the Effect is deleted
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, 172 + bank.clamp(0, 1)))
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :rainbow
      end
    end
  end
end
