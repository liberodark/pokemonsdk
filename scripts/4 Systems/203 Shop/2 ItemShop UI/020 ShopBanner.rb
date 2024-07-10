module UI
  module Shop
    # Banner sprite for the shop
    class ShopBanner < Sprite
      # Base name of the banner (without language modifier)
      FILENAME = 'shop/banner_'

      # Initialize the graphism for the shop banner
      # @param viewport [Viewport] viewport in which the Sprite will be displayed
      def initialize(viewport)
        super(viewport)
        set_bitmap(FILENAME, :interface)
        set_z(4)
      end
    end
  end
end