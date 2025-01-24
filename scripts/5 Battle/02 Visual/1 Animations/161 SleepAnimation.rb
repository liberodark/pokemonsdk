module UI

  class StatusAnimation

    class SleepAnimation < StatusAnimation
      # Get the base position of the status in 1v1
      # @return [Array<Integer, Integer>]
      def status_position_1v1
        return enemy? ? [195, 83] : [135, 109] if battle_3d?

        return enemy? ? [195, 83] : [130, 124]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [154, 76] : [74, 125] if battle_3d?

        return enemy? ? [159, 81] : [119, 104]
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [12, 10]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return enemy? ? 'status/sleep-front' : 'status/sleep-back'
      end
    end
    register(:sleep, SleepAnimation)
  end
end