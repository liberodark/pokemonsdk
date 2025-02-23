module Yuki
  module Animation
    module_function

    # Animation responsive of moving a sprite between a 2 point, one from a sprite defined by a distance
    class RadiusMoveAnimation < TimedAnimation
      # Create a new RadiusMoveAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param a [Symbol] origin sprite position
      # @param b [Integer] length of the movement
      # @param reversed [Boolean] if the animation should be reversed
      # @param max_radius [Integer] max_radius for the angle direction
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, a, b, reversed: false, max_radius: 360, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @origin_sprite = a
        @distance = b
        @max_radius = max_radius
        @reversed = reversed
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        origin_sprite = resolve(@origin_sprite)
        @origin_x = origin_sprite.x
        @origin_y = origin_sprite.y - origin_sprite.bitmap.height / 2

        angle = rand(0...@max_radius)
        @on.angle = (180 - angle) % 360
        cos_angle = Math.cos(angle * Math::PI / 180)
        sin_angle = Math.sin(angle * Math::PI / 180)
        target_x = @origin_x + @distance * cos_angle
        target_y = @origin_y + @distance * sin_angle

        if @reversed
          @delta_x = @origin_x - target_x
          @delta_y = @origin_y - target_y
          @origin_x = target_x
          @origin_y = target_y
        else
          @delta_x = target_x - @origin_x
          @delta_y = target_y - @origin_y
        end
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
      end
    end

    class RadiusMoveMarginAnimation < RadiusMoveAnimation
      # Create a new RadiusMoveMarginAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param a [Symbol] origin sprite position
      # @param b [Integer] length of the movement
      # @param x_margin [Integer] x length of the margin origin
      # @param y_margin [Integer] y length of the margin origin
      # @param reversed [Boolean] if the animation should be reversed
      # @param max_radius [Integer] max_radius for the angle direction
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, a, b, x_margin = 5, y_margin = 5, reversed: false, max_radius: 360,
                     distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, on, a, b, reversed: reversed, max_radius: max_radius,
                                         distortion: distortion, time_source: time_source)
        @x_margin = x_margin
        @y_margin = y_margin
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        dist_margin = Math.sqrt(@x_margin**2 + @y_margin**2) * rand

        @origin_x = origin_sprite.x
        @origin_y = origin_sprite.y - origin_sprite.bitmap.height / 2
        cos_angle = Math.cos(angle * Math::PI / 180)
        sin_angle = Math.sin(angle * Math::PI / 180)
        target_x = @origin_x + @distance * cos_angle
        target_y = @origin_y + @distance * sin_angle

        if @reversed
          @delta_x = @origin_x - target_x + dist_margin * cos_angle
          @delta_y = @origin_y - target_y + dist_margin * sin_angle
          @origin_x = target_x
          @origin_y = target_y
        else
          @delta_x = target_x - @origin_x + dist_margin * cos_angle
          @delta_y = target_y - @origin_y + dist_margin * sin_angle
        end
      end
    end

    # Create a new RadiusMoveAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Symbol] origin sprite position
    # @param b [Integer] length of the movement
    # @param reversed [Boolean] if the animation should be reversed
    # @param max_radius [Integer] max_radius for the angle direction
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [RadiusMoveAnimation]
    def radius_move(time_to_process, on, a, b, reversed: false, max_radius: 360, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      RadiusMoveAnimation.new(time_to_process, on, a, b, reversed: reversed, max_radius: max_radius,
                                                         distortion: distortion, time_source: time_source)
    end

    # Create a new RadiusMoveMarginAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Symbol] origin sprite position
    # @param b [Integer] length of the movement
    # @param x_margin [Integer] x length of the margin origin
    # @param y_margin [Integer] y length of the margin origin
    # @param reversed [Boolean] if the animation should be reversed
    # @param max_radius [Integer] max_radius for the angle direction
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [RadiusMoveMarginAnimation]
    def radius_move_margin(time_to_process, on, a, b, x_margin = 5, y_margin = 5, reversed: false, max_radius: 360,
                           distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      RadiusMoveMarginAnimation.new(time_to_process, on, a, b, x_margin, y_margin, reversed: reversed, max_radius: max_radius,
                                                                                   distortion: distortion, time_source: time_source)
    end
  end
end
