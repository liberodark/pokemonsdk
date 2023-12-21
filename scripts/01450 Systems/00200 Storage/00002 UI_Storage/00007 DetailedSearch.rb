module UI
  module Storage
    # Class responsive of showing a Detailed search
    class DetailedSearch < UI::SpriteStack
      # Name of the button image
      BUTTON_IMAGE = 'button_list_ext'
      # Create a new DetailedSearch
      # @param viewport [Viewport]
      def initialize(viewport)
        super
        create_stack
        # TODO
      end
    end
  end
end
