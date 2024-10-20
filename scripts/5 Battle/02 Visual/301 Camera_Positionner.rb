module Battle
  class Visual3D
    class CameraPositionner

      # Create a new CameraPositionner use for the camera movement
      # @param scene [Scene] scene that hold the logic object
      def initialize(camera)
        @camera = camera
      end

      # @param t [Float] value of x
      def x(t)
        new_x = t
        new_y = @camera.y
        new_z = @camera.z
        @camera.set_position(new_x, new_y, new_z)
      end

      # @param t [Float] value of y
      def y(t)
        new_x = @camera.x
        new_y = t
        new_z = @camera.z
        @camera.set_position(new_x, new_y, new_z)
      end

      # @param t [Float] value of z (0 is illegal)
      def z(t)
        new_x = @camera.x
        new_y = @camera.y
        new_z = t
        @camera.set_position(new_x, new_y, new_z)
      end

      # @param t [Float] value of the translation, apply the same for x and y
      def translation(t)
        new_x = t
        new_y = t
        new_z = @camera.z
        @camera.set_position(new_x, new_y, new_z)
      end

      # Feel free to add new operations
    end
  end
end