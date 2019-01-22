module Yuki
  class Debug
    # Main UI of the debugger
    class MainUI
      # @return [Integer] x position of the GUI on the screen
      SCREEN_X = 322
      # @return [Integer] Number of button required for the MainUI
      BUTTON_COUNT = 8

      # Create a new MainUI for the debug system
      # @param viewport [Viewport] viewport used to display the UI
      def initialize(viewport)
        @manager = GUI::Manager.new(viewport, self, 1280, 22) # 720 / 16
        create_class_text
        create_buttons
      end

      # Update the gui
      def update
        update_class_text
        @manager.update
      end

      private

      # Create the class text
      def create_class_text
        @class_text = @manager.add_label(:class_text, 'TEST', x: SCREEN_X, color: 9)
        @last_scene = nil
      end

      # Update the class text
      def update_class_text
        if $scene != @last_scene
          @last_scene = $scene
          @class_text.text = "Current scene : #{$scene.class}"
        end
      end

      # Create the action button
      def create_buttons
        size_of_button = (1280 - SCREEN_X) / 4
        x = SCREEN_X
        y = 1
        BUTTON_COUNT.times do |index|
          @manager.add_button(index, "Button #{index}", x: x, y: y, width: size_of_button - 1)
          x += size_of_button
          if (index % 4) == 3
            x = SCREEN_X
            y += 1
          end
        end
      end
    end
  end
end