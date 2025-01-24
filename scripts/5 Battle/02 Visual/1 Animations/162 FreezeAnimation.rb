module UI

  class StatusAnimation

    class FreezeAnimation < StatusAnimation
      # Create a new StatusAnimation
      # @param viewport [Viewport]
      # @param status [Symbol] Symbol of the status
      # @param bank [Integer]
      def initialize(viewport, status, bank)
        super
        self.zoom = zoom_value
      end

      # Get the base position of the status in 1v1
      # @return [Array<Integer, Integer>]
      def status_position_1v1
        return enemy? ? [240, 106] : [122, 134] if battle_3d?

        return enemy? ? [242, 98] : [78, 144]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [201, 104] : [73, 160] if battle_3d?

        return enemy? ? [202, 93] : [58, 139]
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [16, 15]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/freeze'
      end
    end
    register(:freeze, FreezeAnimation)
  end
end