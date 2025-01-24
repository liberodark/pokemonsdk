module UI

  class StatusAnimation

    class PoisonAnimation < StatusAnimation
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
        return enemy? ? [239, 98] : [118, 124] if battle_3d?

        return enemy? ? [239, 98] : [78, 144]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [202, 93] : [58, 139] if battle_3d?

        return enemy? ? [202, 93] : [58, 139]
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [12, 10]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/poison'
      end

      # Return the duration of the Status Animation
      # @param [Integer]
      def status_duration
        return 1.2
      end
    end
    register(:poison, PoisonAnimation)
    register(:toxic, PoisonAnimation)
  end
end