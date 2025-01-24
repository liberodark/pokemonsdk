module UI

  class StatusAnimation

    class AttractAnimation < StatusAnimation
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
        return enemy? ? [235, 62] : [106, 120] if battle_3d?

        return enemy? ? [242, 98] : [78, 134]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [201, 104] : [53, 160] if battle_3d?

        return enemy? ? [202, 93] : [58, 129]
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [18, 17]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/attract'
      end
    end
    register(:attract, AttractAnimation)
  end
end