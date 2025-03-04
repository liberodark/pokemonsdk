module Yuki
  # This file contains the definition and methods of Yuki::Animation distorting and affecting the sprite
  # These animation (from this file to 99) planed to be used on PokemonSprite (and PokemonSprite3D)
  # Some of them could work with classic Sprite, but none all of them so be sure to check the code of an
  # animation before using it.
  module Animation
    module_function

    class ParticleZoomAnimation < TimedAnimation
      # Create a new ParticleZoomAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
      # @param a [Float] zoom_start
      # @param b [Float] zoom_final
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @on_param = on
        @zoom_start = a
        @zoom_final = b
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @pokemon_sprite = resolve(@on_param)
        @particle = resolve(@particle_param)

        @origin_x = @pokemon_sprite.x
        @origin_y = @pokemon_sprite.y

        sprite_zoom = @pokemon_sprite.sprite_zoom
        @zoom_start *= sprite_zoom
        @zoom_final *= sprite_zoom
        @delta_zoom = @zoom_final - @zoom_start
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.zoom = @zoom_start + @delta_zoom * time_factor
      end
    end

    class ParticleZoomXAnimation < ParticleZoomAnimation
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.zoom_x = @zoom_start + @delta_zoom * time_factor
      end
    end

    class ParticleZoomYAnimation < ParticleZoomAnimation
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.zoom_y = @zoom_start + @delta_zoom * time_factor
      end
    end

    # Create a new ParticleZoomAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
    # @param a [Float] zoom_start
    # @param b [Float] zoom_final
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    def particle_zoom(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      ParticleZoomAnimation.new(time_to_process, particle, on, a, b, distortion: distortion, time_source: time_source)
    end

    # Create a new ParticleZoomXAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
    # @param a [Float] zoom_start
    # @param b [Float] zoom_final
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    def particle_zoom_x(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      ParticleZoomXAnimation.new(time_to_process, particle, on, a, b, distortion: distortion, time_source: time_source)
    end

    # Create a new ParticleZoomYAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
    # @param a [Float] zoom_start
    # @param b [Float] zoom_final
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    def particle_zoom_y(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      ParticleZoomYAnimation.new(time_to_process, particle, on, a, b, distortion: distortion, time_source: time_source)
    end
  end
end