module UI

  class StatusAnimation

    class BurnAnimation < StatusAnimation
      # Get the base position of the status in 1v1
      # @return [Array<Integer, Integer>]
      def status_position_1v1
        return enemy? ? [241, 131] : [111, 186] if battle_3d?

        return enemy? ? [242, 123] : [78, 164]
      end

      # Get the base position of the status in 2v2
      # @return [Array<Integer, Integer>]
      def status_position_2v2
        return enemy? ? [200, 122] : [69, 202] if battle_3d?

        return enemy? ? [202, 118] : [58, 164]
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [9, 8]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/burn'
      end
    end
    register(:burn, BurnAnimation)
  end
end