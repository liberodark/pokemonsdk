module Battle
  module Effects
    # Effect lowering Electric moves
    class MudSport < EffectBase
      # Create a new effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      def initialize(logic)
        super
        self.counter = 5
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :mud_sport
      end

      # Show the message when the effect gets deleted
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, 121))
      end
    end

    # Effect lowering Fire moves
    class WaterSport < MudSport
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :water_sport
      end

      # Show the message when the effect gets deleted
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, 119))
      end
    end
  end
end
