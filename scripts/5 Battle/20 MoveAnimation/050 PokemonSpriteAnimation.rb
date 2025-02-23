module Yuki
  # This file contains the definition and methods of Yuki::Animation distorting and affecting the sprite
  # These animation (from this file to 99) planed to be used on PokemonSprite (and PokemonSprite3D)
  # Some of them could work with classic Sprite, but none all of them so be sure to check the code of an
  # animation before using it.
  module Animation
    module_function

    # Class that performs a compress Animation

    class CompressAnimation < TimedAnimation
      # Create a new CompressAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param a [Integer] value in x retrieved to the sprite_zoom
      # @param b [Integer] value in y retrieved to the sprite_zoom
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, a, b, distortion: :SQUARE010_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @compress_x = a
        @compress_y = b
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        @origin = @on.sprite_zoom
        @delta_x = @compress_x
        @delta_y = @compress_y
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.zoom_x = @origin + @delta_x * time_factor
        @on.zoom_y = @origin + @delta_y * time_factor
      end
    end

    # Create a new CompressAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Integer] value in x retrieved to the sprite_zoom
    # @param b [Integer] value in y retrieved to the sprite_zoom
    # @param iteration [#call, Integer] number of iteration of the animation
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [CompressAnimation]
    def compress(time_to_process, on, a, b, iteration: 1, distortion: :SQUARE010_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      animation = CompressAnimation.new(time_to_process, on, a, b, distortion: distortion, time_source: time_source)
      (iteration - 1).times do
        animation.play_before(CompressAnimation.new(time_to_process, on, a, b, distortion: distortion, time_source: time_source))
      end

      return animation
    end
  end
end
