module Battle
  module Effects
    class Wish < PositionTiedEffectBase
      # Create a new position tied effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      # @param bank [Integer] bank where the effect is tied
      # @param position [Integer] position where the effect is tied
      def initialize(logic, bank, position, hp)
        super(logic, bank, position)
        @pokemon = @logic.battler(bank, position)
        @hp = hp
        @counter = 2
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        pkm = @logic.battler(bank, position)
        @logic.scene.visual.show_hp_animations([pkm], [@hp]) if pkm && !pkm.dead?
        @logic.scene.display_message_and_wait(message)
      end

      def name
        return :wish
      end

      # Get the message text
      # @return [String]
      def message
        parse_text_with_pokemon(19, 700, @pokemon)
      end
    end
  end
end
