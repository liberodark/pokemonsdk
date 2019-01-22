module Yuki
  class ChoiceWindow
    # Display a Choice "Window" but showing buttons instead of the common window
    class But < ChoiceWindow
      # Window Builder of this kind of choice window
      WindowBuilder = [5, 0, 62, 16, 8, 0]
      # Overwrite the current window_builder
      # @return [Array]
      def current_window_builder
        WindowBuilder
      end

      # Overwrite the windowskin setter
      # @param v [LiteRGSS::Bitmap] ignored
      def windowskin=(v)
        super(RPG::Cache.interface('team/But_Choice'))
      end
    end
  end
end