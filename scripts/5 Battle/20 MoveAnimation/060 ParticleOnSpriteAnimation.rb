module Yuki
  # This file contains the definition and methods of Yuki::Animation distorting and affecting the sprite
  # These animation (from this file to 99) planed to be used on PokemonSprite (and PokemonSprite3D)
  # Some of them could work with classic Sprite, but none all of them so be sure to check the code of an
  # animation before using it.
  # This file contains animations related to a particle. This particle is always linked to a PokemonSprite (it used sprite_zoom to make the
  # animation looks great either in 2D and 3D)
  module Animation
    module_function

    class ParticleOnSpriteAnimation < TimedAnimation
      # Create a new ParticleOnSpriteAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
      # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
      # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, on, proportion_x = 1, proportion_y = 1, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @on_param = on
        @proportion_x = proportion_x
        @proportion_y = proportion_y
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @pokemon_sprite = resolve(@on_param)
        @particle = resolve(@particle_param)
        sprite_zoom = @pokemon_sprite.sprite_zoom

        @origin_x = @pokemon_sprite.x
        @origin_y = @pokemon_sprite.y - @pokemon_sprite.bitmap.height / 2 * sprite_zoom

        @delta_x = (@pokemon_sprite.bitmap.width / 2 * sprite_zoom * (rand * 2 - 1) * @proportion_x).to_i
        @delta_y = (@pokemon_sprite.bitmap.height / 2 * sprite_zoom * (rand * 2 - 1) * @proportion_y).to_i
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y - @delta_y * time_factor)
      end
    end

    # Place a particle on a sprite with an offset
    class ParticleOnSpriteOffset < Command
      # Create a new ParticleOnSpriteOffset
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
      # @param offset_x [Integer] (by default 0)
      # @param offset_y [Integer] (by default 0)
      def initialize(particle, on, offset_x = 0, offset_y = 0)
        super()
        @particle_param = particle
        @on_param = on
        @offset_x = offset_x
        @offset_y = offset_y
      end

      private

      # Execute the placement of the particle on the sprite with the offset
      def update_internal
        pokemon_sprite = resolve(@on_param)
        particle = resolve(@particle_param)
        sprite_zoom = pokemon_sprite.sprite_zoom

        origin_x = pokemon_sprite.x + @offset_x * sprite_zoom
        origin_y = pokemon_sprite.y + @offset_y * sprite_zoom
        particle.set_position(origin_x, origin_y)
      end
    end

    # Place a particle on a sprite with an offset
    class ParticleOnSpriteRandom < Command
      # Create a new ParticleOnSpriteRandom
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
      # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
      # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
      def initialize(particle, on, proportion_x = 1, proportion_y = 1)
        super()
        @particle_param = particle
        @on_param = on
        @proportion_x = proportion_x
        @proportion_y = proportion_y
      end

      private

      # Execute the placement of the particle on the sprite with the offset
      def update_internal
        pokemon_sprite = resolve(@on_param)
        particle = resolve(@particle_param)
        sprite_zoom = pokemon_sprite.sprite_zoom
        rand_x = 2 * rand - 1 # return a number between -1 and 1
        rand_y = 2 * rand - 1
        offset_center = pokemon_sprite.bitmap.height / 2 * sprite_zoom # make the coordinates from the center of the sprite

        origin_x = pokemon_sprite.x + (pokemon_sprite.bitmap.width * @proportion_x * rand_x * sprite_zoom).to_i
        origin_y = pokemon_sprite.y - offset_center + (pokemon_sprite.bitmap.height * @proportion_y * rand_y * sprite_zoom).to_i
        particle.set_position(origin_x, origin_y)
      end
    end

    # Create a new MoveParticleOnSprite

    class MoveParticleOnSprite < TimedAnimation
      # Create a new MoveParticleOnSprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will moved
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will navigate
      # @param start_x [Integer]
      # @param start_y [Integer]
      # @param final_x [Integer]
      # @param final_y [Integer]
      # @param use_zoom [Boolean] use zoom of the sprite (by default true)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, on, start_x, start_y, final_x, final_y, use_zoom: true,
                     distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @on_param = on
        @use_zoom = use_zoom
        @start_x = start_x
        @start_y = start_y
        @final_x = final_x
        @final_y = final_y
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        pokemon_sprite = resolve(@on_param)
        @particle = resolve(@particle_param)
        sprite_zoom = @use_zoom ? pokemon_sprite.sprite_zoom : 1

        @origin_x = pokemon_sprite.x + @start_x * sprite_zoom
        @origin_y = pokemon_sprite.y + @start_y * sprite_zoom
        final_x = pokemon_sprite.x + @final_x * sprite_zoom
        final_y = pokemon_sprite.y + @final_y * sprite_zoom

        @delta_x = final_x - @origin_x
        @delta_y = final_y - @origin_y
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
      end
    end

    # Create a new MoveParticleOnSprite
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will moved
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will navigate
    # @param start_x [Integer]
    # @param start_y [Integer]
    # @param final_x [Integer]
    # @param final_y [Integer]
    # @param use_zoom [Boolean] use zoom of the sprite (by default true)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveParticleOnSprite]
    def move_particle_on_sprite(time_to_process, particle, on, start_x, start_y, final_x, final_y, use_zoom: true,
                                distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      MoveParticleOnSprite.new(time_to_process, particle, on, start_x, start_y, final_x, final_y, use_zoom: use_zoom,
                                                                                                  distortion: distortion, time_source: time_source)
    end

    # Create a new ParticleOnSpriteOffset
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
    # @param offset_x [Integer] (by default 0)
    # @param offset_y [Integer] (by default 0)
    # @return [ParticleOnSpriteOffset]
    def particle_on_sprite_command(particle, on, offset_x = 0, offset_y = 0)
      ParticleOnSpriteOffset.new(particle, on, offset_x, offset_y)
    end

    # Create a new ParticleOnSpriteRandom
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
    # @param proportion_x [Integer] (by default 1)
    # @param proportion_y [Integer] (by default 1)
    # @return [ParticleOnSpriteRandom]
    def particle_random_sprite_command(particle, on, proportion_x = 1, proportion_y = 1)
      ParticleOnSpriteRandom.new(particle, on, proportion_x, proportion_y)
    end

    # Create a new ParticleOnSpriteAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
    # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
    # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ParticleOnSpriteAnimation]
    def particle_on_sprite(time_to_process, particle, on, proportion_x = 1, proportion_y = 1, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      ParticleOnSpriteAnimation.new(time_to_process, particle, on, proportion_x, proportion_y, distortion: distortion, time_source: time_source)
    end
  end
end