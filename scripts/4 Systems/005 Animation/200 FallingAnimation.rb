module Yuki
  module Animation
    module_function

    # Class that performs a 2D falling animation
    class FallingAnimation < TimedAnimation
      # Create a new FallingAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param a [Symbol] Sprite that should hit
      # @param b [Float, Integer] distance of the fall
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, a, b, distortion: :FALLING_SMOOTH,
                     time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @destination_sprite = a
        @distance = b
        @on_param = on
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        destination_sprite = resolve(@destination_sprite)
        @distance *= destination_sprite.sprite_zoom

        @on.x = destination_sprite.x
        @origin_y = destination_sprite.y - @distance
      end

      private

      # Update the falling animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.y = @origin_y + @distance * time_factor
      end
    end

    # Create a new FallingAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Symbol] Sprite that should hit
    # @param b [Float, Integer] distance of the fall
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveSpritePosition]
    def falling_animation(time_to_process, on, a, b, distortion: :FALLING_SMOOTH, time_source: :SCENE_TIME_SOURCE)
      FallingAnimation.new(time_to_process, on, a, b, distortion: distortion, time_source: time_source)
    end
  end
end
