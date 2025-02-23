module Yuki
  module Animation
    module_function

    class ToneAnimation < TimedAnimation
      # Create a new ToneAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param a [Array(Integer, Integer, Integer, Integer)] origin_tone
      # @param b [Array(Integer, Integer, Integer, Integer)] tone wanted
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converts it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @origin_tone = a
        @destination_tone = b
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        @tone_delta = @origin_tone.zip(@destination_tone).map { |orig, dest| dest - orig }
      end

      # Update the animation, interpolating the tone values
      # @param time_factor [Float] number between 0 and 1 indicating the progression of the animation
      def update_internal(time_factor)
        interpolated_tone = @origin_tone.zip(@tone_delta).map { |origin, delta| origin + delta * time_factor }
        @on.shader.set_float_uniform('color', interpolated_tone)
      end
    end

    # Create a new ToneAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Array(Integer, Integer, Integer, Integer)] Initial tone values for the animation.
    # @param b [Array(Integer, Integer, Integer, Integer)] Target tone values for the animation.
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ToneAnimation]
    def tone_animation(time_to_process, on, a, b = a, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      ToneAnimation.new(time_to_process, on, a, b, distortion: distortion, time_source: time_source)
    end
  end
end
