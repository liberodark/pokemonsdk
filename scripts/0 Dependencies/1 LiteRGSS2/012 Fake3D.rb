# Module holding the core logic for Fake3D
module Fake3D
  # Constant to set to true if you intent on using Fake3D in your project
  ENABLED = false

  # Module to prepend to one of your Sprite class to make them Fake3D able
  module Sprite3D
    def initialize(viewport)
      super(viewport)
      self.shader = Shader.create(:fake_3d)
      self.z = 1
    end

    # Set the z position of the sprite
    # @param z [Numeric]
    def z=(z)
      super(1000 - z)
      shader.set_float_uniform('z', z)
    end

    # Set the position of the sprite
    # @param x [Integer] x position of the sprite (Warning, 0 is most likely the center of the viewport)
    # @param y [Integer] y position of the sprite (Warning, y still goes to the bottom, 0 is most likely the center of the viewport)
    # @param z [Numeric] z position of the sprite (1 is most likely at scale, 2 is smaller, 0 is illegal)
    def set_position(x, y, z = nil)
      super(x, y)
      self.z = z if z
    end
  end

  # Camera of a Fake3D scene
  #
  # This class is used to help Sprite3D to render at the right position by applying a camera matrix
  class Camera
    # Minimum Z the camera can go
    MIN_Z = 0.1

    # Get the camera pitch
    # @return [Numeric]
    attr_reader :pitch

    # Get the camera yaw
    # @return [Numeric]
    attr_reader :yaw

    # Get the camera roll
    # @return [Numeric]
    attr_reader :roll

    # Check if the camera was updated
    # @return [Boolean]
    attr_reader :was_updated

    # Get the z coordinate of the camera
    # @return [Numeric]
    attr_reader :z

    # Create a new Camera
    # @param viewport [Viewport] viewport used to compute the projection matrix
    def initialize(viewport)
      require 'matrix' unless defined?(Matrix)
      @pitch = 0
      @yaw = 0
      @roll = 0
      @txy_matrix = Matrix[[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
      @scale_tz_matrix = Matrix[[2, 0, 0, 0.0], [0, 2, 0, 0.0], [0, 0, 1, 0.0], [0, 0, 0, 2.0]]
      @rotation_matrix = Matrix[[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
      @projection_matrix = projection_matrix(viewport)
      @was_updated = true
      @z = 1
    end

    # Set the camera rotation
    # @param yaw [Integer] angle around axis z
    # @param pitch [Integer] angle around axis y
    # @param roll [Integer] angle around axis x
    def set_rotation(yaw, pitch, roll)
      @was_updated = true
      @pitch = pitch % 360
      @yaw = yaw % 360
      @roll = roll % 360
      @rotation_matrix = pitch_yaw_roll(@pitch, @yaw, @roll)
    end

    # Set the camera position
    # @param x [Numeric] x position of the camera
    # @param y [Numeric] y position of the camera
    # @param z [Numeric] z position of the camera (z = 1 => sprite of z = 1 at scale, sprite of z = 2 demi scale, z = 2 => sprite of z = 1 might disappear, sprite of z = 2 at scale)
    def set_position(x, y, z)
      @was_updated = true
      apply_z(z)
      @txy_matrix[0, 3] = -x
      @txy_matrix[1, 3] = -y
    end

    # Get the x coordinate of the camera
    # @return [Numeric]
    def x
      return -@txy_matrix[0, 3]
    end

    # Get the y coordinate of the camera
    # @return [Numeric]
    def y
      return -@txy_matrix[1, 3]
    end

    # Apply the camera to a sprite
    # @param sprite [Sprite3D, Array<Sprite3D>]
    def apply_to(sprite)
      @camera_matrix = compute_matrix if @was_updated
      uniform = 'camera'
      if sprite.is_a?(Array)
        sprite.each { |sp| sp.shader.set_matrix_uniform(uniform, @camera_matrix) }
      else
        sprite.shader.set_matrix_uniform(uniform, @camera_matrix)
      end
    end

    private

    # Apply the Z of the camera. Overwrite this method to apply your own z computation
    # @param z [Float]
    def apply_z(z)
      z = z.clamp(MIN_Z, Float::INFINITY)
      @scale_tz_matrix[3, 3] = 1 / (0.5 * z)
      @z = z
    end

    def pitch_yaw_roll(pitch, yaw, roll)
      pitch *= Math::PI / 180
      yaw *= Math::PI / 180
      roll *= Math::PI / 180
      cos_beta = Math.cos(pitch)
      sin_beta = Math.sin(pitch)
      cos_alpha = Math.cos(yaw)
      sin_alpha = Math.sin(yaw)
      cos_gamma = Math.cos(roll)
      sin_gamma = Math.sin(roll)
    
      return Matrix[[
        cos_alpha * cos_beta,
        cos_alpha * sin_beta * sin_gamma - sin_alpha * cos_gamma,
        cos_alpha * sin_beta * cos_gamma + sin_alpha * sin_gamma,
        0
      ], [
        sin_alpha * cos_beta,
        sin_alpha * sin_beta * sin_gamma + cos_alpha * cos_gamma,
        sin_alpha * sin_beta * cos_gamma - cos_alpha * sin_gamma,
        0
      ], [
        -sin_beta,
        cos_beta * sin_gamma,
        cos_beta * cos_gamma,
        0
      ], [0, 0, 0, 1]]
    end

    # @param viewport [Viewport] viewport used to compute the projection matrix
    def projection_matrix(viewport)
      a = 2 / viewport.rect.width.to_f
      b = -2 / viewport.rect.height.to_f

      return Matrix[[a, 0, 0, 0], [0, b, 0, 0], [0, 0, 0, 1], [0, 0, 1, 0]]
    end

    def compute_matrix
      @was_updated = false
      return (@scale_tz_matrix * @rotation_matrix * @projection_matrix * @txy_matrix).transpose.to_a.flatten
    end
  end
end