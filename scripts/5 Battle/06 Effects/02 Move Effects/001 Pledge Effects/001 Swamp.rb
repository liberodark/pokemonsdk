module Battle
  module Effects
    class Swamp < PositionTiedEffectBase
      # Create a Swamp effect (Grass Pledge + Water Pledge)
      # @param logic [Battle::Logic]
      # @param bank [Integer] bank where the effect acts
      def initialize(logic, bank)
        super(logic, bank, 0)
        self.counter = 4
        effect_creation_text
      end

      # Give the speed modifier over given to the Pokemon with this effect
      # @return [Float, Integer] multiplier
      def spd_modifier
        return 0.25
      end

      # Display the message associated with the effect's creation  
      def effect_creation_text
        @logic.scene.display_message_and_wait(parse_text(18, 178 + bank.clamp(0, 1)))
      end

      # Method called when the Effect is deleted
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, 180 + bank.clamp(0, 1)))
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :swamp
      end
    end
  end
end
