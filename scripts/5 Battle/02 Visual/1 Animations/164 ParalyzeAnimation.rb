module UI

  class StatusAnimation

    class ParalyzeAnimation < StatusAnimation
      # Get the base position of the status in 1v1
      # @return [Array<Integer, Integer>]
      def status_position_1v1
        return enemy? ? [242, 114] : [114, 162] if battle_3d?

        return enemy? ? [242, 98] : [78, 144]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [201, 96] : [66, 164] if battle_3d?

        return enemy? ? [202, 108] : [58, 144]
      end

      def offset_position_v2
        return 80, 10 if battle_3d? && !enemy?

        return 60, 10
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [10, 8]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/paralysis'
      end
    end
    register(:paralysis, ParalyzeAnimation)
  end
end