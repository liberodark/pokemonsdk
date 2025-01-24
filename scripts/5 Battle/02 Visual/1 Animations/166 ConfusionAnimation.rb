module UI

  class StatusAnimation

    class ConfusionAnimation < StatusAnimation
      # Create a new StatusAnimation
      # @param viewport [Viewport]
      # @param status [Symbol] Symbol of the status
      # @param bank [Integer]
      def initialize(viewport, status, bank)
        super
        self.zoom = zoom_value
      end

      # Return the duration of the Status Animation
      # @param [Integer]
      def status_duration
        return 2
      end

      # Get the base position of the status in 1v1
      # @return [Array<Integer, Integer>]
      def status_position_1v1
        return enemy? ? [235, 73] : [113, 98] if battle_3d?

        return enemy? ? [242, 78] : [78, 124]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [198, 62] : [56, 96] if battle_3d?

        return enemy? ? [202, 73] : [58, 119]
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [12, 12]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/confusion'
      end
    end
    register(:confusion, ConfusionAnimation)
  end
end