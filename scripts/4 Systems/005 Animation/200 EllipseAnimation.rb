module Yuki
  module Animation
    module_function

    # Class that performs a 2D elliptical animation (follows an ellipse)
    class EllipseAnimation < TimedAnimation
      # Create a new EllipseAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param property [Symbol] name of the property to affect (add the = sign in the symbol name)
      # @param a [Float, Symbol] semi-major axis (horizontal radius)
      # @param b [Float, Symbol] semi-minor axis (vertical radius)
      # @param turn [Integer, float] number of turns
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, property, a, b, turn: 1, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @a_param = a
        @b_param = b
        @on_param = on
        @property = property
        @turn = turn
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        @a = resolve(@a_param)
        @b = resolve(@b_param)
        @center_x = @on.x
        @center_y = @on.y + @b
      end

      private

      # Update the ellipse animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        # Calculate the angle (from 0 to 2π) based on the time factor
        angle = 2 * Math::PI * time_factor * @turn - Math::PI / 2
        # Compute the x and y coordinates based on the ellipse equation
        x = @center_x + @a * Math.cos(angle)
        y = @center_y + @b * Math.sin(angle)
        @on.send(@property, x, y)
      end
    end

    # Create an ellipse animation (follows an elliptical trajectory)
    # @param during [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Float, Symbol] semi-major axis (horizontal radius)
    # @param b [Float, Symbol] semi-minor axis (vertical radius)
    # @param turn [Integer] number of turns
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    def ellipse(during, on, a, b, turn: 1, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      EllipseAnimation.new(during, on, :set_position, a, b, turn: turn, distortion: distortion, time_source: time_source)
    end
  end
end
