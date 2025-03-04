module Yuki
  module Animation
    module_function

    class MoveParticleAnimation < TimedAnimation
      # Create a new MoveParticleAnimation
      # @note Create an animation between two sprites, an offset will be randomly choose for each coordinates depending of the proportion parameters,
      # if 0, it will stay on the origin, at 1 it can placed everywhere on the sprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be moved
      # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
      # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
      # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
      # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
      # @param use_zoom [Boolean] is the zoom difference used (by default false)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, from, to, proportion_x = 1, proportion_y = 1, use_zoom: false,
                     distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @from_param = from
        @to_param = to
        @use_zoom = use_zoom
        @proportion_x = proportion_x
        @proportion_y = proportion_y
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        # Determine which sprite is the origin and the destination and calc the delta between them with an offset chose randomly based on the proportion parameters
        @origin_sprite = resolve(@from_param)
        @destination_sprite = resolve(@to_param)
        @particle = resolve(@particle_param)
        destination_zoom = @use_zoom ? @destination_sprite.sprite_zoom : 1
        @origin_zoom = @use_zoom ? @origin_sprite.sprite_zoom : 1

        rand_x = rand * 2 - 1
        rand_y = rand * 2 - 1

        origin_x = @origin_sprite.x
        origin_y = @origin_sprite.y - @origin_sprite.bitmap.height / 2 * @origin_zoom
        @origin_x = origin_x + (@origin_sprite.bitmap.width / 2 * @origin_zoom * rand_x * @proportion_x).to_i
        @origin_y = origin_y + (@origin_sprite.bitmap.height / 2 * @origin_zoom * rand_y * @proportion_y).to_i

        destination_x = @destination_sprite.x
        destination_y = @destination_sprite.y - @origin_sprite.bitmap.height / 2 * destination_zoom
        @destination_x = destination_x + (@destination_sprite.bitmap.width / 2 * destination_zoom * rand_x * @proportion_x).to_i
        @destination_y = destination_y + (@destination_sprite.bitmap.height / 2 * destination_zoom * rand_y * @proportion_y).to_i

        @delta_x = @destination_x - @origin_x
        @delta_y = @destination_y - @origin_y
        @delta_zoom = destination_zoom - @origin_zoom
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
        @particle.zoom = @origin_zoom + @delta_zoom * time_factor if @use_zoom
      end
    end

    class MoveParticleOffsetAnimation < TimedAnimation
      # Create a new MoveParticleOffsetAnimation
      # @note Create an animation between two sprites with the possibility to apply an offset in both coordinates between the sprites
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be moved
      # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
      # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
      # @param offset_x [Integer] offset on x
      # @param offset_y [Integer] offset on y
      # @param from_center [Boolean] is the origin from the center of the sprite (by default false)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, from, to, offset_x, offset_y, from_center: false,
                     distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @from_param = from
        @to_param = to
        @offset_x = offset_x
        @offset_y = offset_y
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        # Determine which sprite is the origin and the destination and calc the delta between them with the offset in each coordinates
        @origin_sprite = resolve(@from_param)
        @destination_sprite = resolve(@to_param)
        @particle = resolve(@particle_param)
        destination_zoom = @destination_sprite.sprite_zoom
        @origin_zoom = @origin_sprite.sprite_zoom
        center_y = @from_center ? @origin_sprite.bitmap.height / 2 : 0

        @origin_x = @origin_sprite.x
        @origin_y = @origin_sprite.y - center_y * @origin_zoom

        @destination_x = @destination_sprite.x + @offset_x * destination_zoom
        @destination_y = @destination_sprite.y + @offset_y * destination_zoom

        @delta_x = @destination_x - @origin_x
        @delta_y = @destination_y - @origin_y
        @delta_zoom = destination_zoom - @origin_zoom
      end

      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
        @particle.zoom = @origin_zoom + @delta_zoom * time_factor if @use_zoom
      end
    end

    # Create a new MoveParticleAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be moved
    # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
    # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
    # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
    # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
    # @param use_zoom [Boolean] is the zoom difference used (by default false)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveParticleAnimation]
    def particle_move_to_sprite(time_to_process, particle, from, to, proportion_x = 1, proportion_y = 1, use_zoom: false,
                                distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      MoveParticleAnimation.new(time_to_process, particle, from, to, proportion_x, proportion_y, use_zoom: use_zoom,
                                                                                                 distortion: distortion, time_source: time_source)
    end

    # Create a new MoveParticleOffsetAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be moved
    # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
    # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
    # @param offset_x [Integer] offset on x
    # @param offset_y [Integer] offset on y
    # @param from_center [Boolean] is the origin from the center of the sprite (by default false)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveParticleOffsetAnimation]
    def particle_move_to_sprite_offset(time_to_process, particle, from, to, offset_x = 0, offset_y = 0, from_center: false,
                                       distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      MoveParticleOffsetAnimation.new(time_to_process, particle, from, to, offset_x, offset_y, from_center: from_center, distortion: distortion,
                                                                                               time_source: time_source)
    end
  end
end
