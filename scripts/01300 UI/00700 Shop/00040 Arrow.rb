module UI
  module Shop
    class Arrow < UI::Bag::Arrow
      # Initialize the arrow Sprite for the UI
      # @param viewport [Viewport] the viewport in which the Sprite will be displayed
      def initialize(viewport)
        super
        set_position(105, 79)
        set_bitmap('bag/arrow', :interface)
        self.z = 4
        @counter = 0
      end
    end
  end
end