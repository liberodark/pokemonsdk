module Yuki
  # This file contains the definition and methods of Yuki::Animation distorting and affecting the sprite
  # These animation (from this file to 99) planed to be used on PokemonSprite (and PokemonSprite3D)
  # Some of them could work with classic Sprite, but none all of them so be sure to check the code of an
  # animation before using it.
  module Animation
    module_function

    class ScalarXFromSprite < TimedAnimation
      # Create a new ScalarXFromSprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param sprite [Object] on which the origin will be based on
      # @param start_x [Integer] start_x
      # @param offset_x [Integer] offset_x
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, sprite, start_x, offset_x, distortion: :UNICITY_DISTORTION,
                     time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @sprite_param = sprite
        @start_x = start_x
        @offset_x = offset_x
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        pokemon_sprite = resolve(@sprite_param)
        @on = resolve(@on_param)
        sprite_zoom = pokemon_sprite.sprite_zoom

        @origin_x = pokemon_sprite.x + @start_x * sprite_zoom
        @offset_x *= sprite_zoom
      end

      # Update the scalar animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.x = @origin_x + @offset_x * time_factor
      end
    end

    class ScalarYFromSprite < TimedAnimation
      # Create a new ScalarYFromSprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param sprite [Object] on which the origin will be based on
      # @param start_y [Integer] start_y
      # @param offset_y [Integer] offset_y
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, sprite, start_y, offset_y, distortion: :UNICITY_DISTORTION,
                     time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @sprite_param = sprite
        @start_y = start_y
        @offset_y = offset_y
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        pokemon_sprite = resolve(@sprite_param)
        @on = resolve(@on_param)
        sprite_zoom = pokemon_sprite.sprite_zoom

        @origin_y = pokemon_sprite.y + @start_y * sprite_zoom
        @offset_y *= sprite_zoom
      end

      # Update the scalar animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.y = @origin_y + @offset_y * time_factor
      end
    end

    # Create a scalar animation on the x property of an element, linked to a sprite for the original position
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param sprite [Object] on which the origin will be based on
    # @param start_x [Integer] start_x
    # @param offset_x [Integer] offset_x
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ScalarXFromSprite]
    def scalar_x_from_sprite(time_to_process, on, sprite, start_x, offset_x, distortion: :UNICITY_DISTORTION,
                             time_source: :SCENE_TIME_SOURCE)
      ScalarXFromSprite.new(time_to_process, on, sprite, start_x, offset_x, distortion: distortion, time_source: time_source)
    end

    # Create a scalar animation on the y property of an element, linked to a sprite for the original position
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param sprite [Object] on which the origin will be based on
    # @param start_y [Integer] start_y
    # @param offset_y [Integer] offset_y
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ScalarYFromSprite]
    def scalar_y_from_sprite(time_to_process, on, sprite, start_y, offset_y, distortion: :UNICITY_DISTORTION,
                             time_source: :SCENE_TIME_SOURCE)
      ScalarYFromSprite.new(time_to_process, on, sprite, start_y, offset_y, distortion: distortion, time_source: time_source)
    end
  end
end
