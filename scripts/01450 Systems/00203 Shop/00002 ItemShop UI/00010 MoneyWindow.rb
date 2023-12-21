module UI
  module Shop
    # Window displaying the money amount
    class MoneyWindow < SpriteStack
      # X coordinate of the money window
      COORD_X = 7
      # Y coordinate of the money window
      COORD_Y = 4
      # Black color
      BLACK_COLOR = Color.new(0, 0, 0)
      # White color
      WHITE_COLOR = Color.new(255, 255, 255)

      # Initializing the money window graphics and texts
      # @param viewport [Viewport] viewport in which the SpriteStack will be displayed
      def initialize(viewport)
        super(viewport, COORD_X, COORD_Y)
        @money_window = add_background('shop/money_window')
        @money_text = add_text(5, 7, 34, 11, parse_text(11, 6) + ' :')
        @money_text.fill_color = WHITE_COLOR
        @money_text.draw_shadow = false
        @money_quantity = add_text(52, 8, 66, 9, nil.to_s, 2)
        @money_quantity.fill_color = WHITE_COLOR
        @money_quantity.draw_shadow = false
        self.z = 4
      end

      # Update the money text
      # @param text [String] the new string to display
      def text=(text)
        @money_quantity.text = text
      end
    end
  end
end
