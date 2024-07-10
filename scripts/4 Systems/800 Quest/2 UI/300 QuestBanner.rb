module UI
  module Quest
    # Frame UI element for quests
    class QuestFrame < Sprite
      # Name of the file holding the quest frame
      FILENAME = 'quest/frame'
      # Initialize the graphism for the shop banner
      # @param viewport [Viewport] viewport in which the Sprite will be displayed
      def initialize(viewport)
        super(viewport)
        set_bitmap(FILENAME, :interface)
      end
    end
  end
end
