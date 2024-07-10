# Class that describe a sprite shown on the screen or inside a viewport
class Sprite < LiteRGSS::ShaderedSprite
  # RGSS Compatibility "update" the sprite
  def update
    return nil
  end

  # define the superiority of the sprite
  # @param z [Integer] superiority
  # @return [self]
  def set_z(z)
    self.z = z
    return self
  end

  # define the pixel of the bitmap that is shown at the coordinate of the sprite.
  # The width and the height is divided by ox and oy to determine the pixel
  # @param ox [Numeric] factor of division of width to get the origin x
  # @param oy [Numeric] factor of division of height to get the origin y
  # @return [self]
  def set_origin_div(ox, oy)
    self.ox = bitmap.width / ox
    self.oy = bitmap.height / oy
    return self
  end

  # Define the surface of the bitmap that is shown on the screen surface
  # @param x [Integer] x coordinate on the bitmap
  # @param y [Integer] y coordinate on the bitmap
  # @param width [Integer] width of the surface
  # @param height [Integer] height of the surface
  # @return [self]
  def set_rect(x, y, width, height)
    src_rect.set(x, y, width, height)
    return self
  end

  # Define the surface of the bitmap that is shown with division of it
  # @param x [Integer] the division index to show on x
  # @param y [Integer] the division index to show on y
  # @param width [Integer] the division of width of the bitmap to show
  # @param height [Integer] the division of height of the bitmap to show
  # @return [self]
  def set_rect_div(x, y, width, height)
    width = bitmap.width / width
    height = bitmap.height / height
    src_rect.set(x * width, y * height, width, height)
    return self
  end

  # Set the texture show on the screen surface
  # @overload load(filename, cache_symbol)
  #   @param filename [String] the name of the image
  #   @param cache_symbol [Symbol] the symbol method to call with filename argument in RPG::Cache
  #   @param auto_rect [Boolean] if the rect should be automatically set
  # @overload load(bmp)
  #   @param texture [Texture, nil] the bitmap to show
  # @return [self]
  def load(texture, cache = nil, auto_rect = false)
    if cache && texture.is_a?(String)
      self.bitmap = RPG::Cache.send(cache, texture)
      set_rect_div(0, 0, 4, 4) if auto_rect && cache == :character
    else
      self.bitmap = texture
    end
    return self
  end
  alias set_bitmap load

  # Define a sprite that mix with a color
  class WithColor < Sprite
    # Create a new Sprite::WithColor
    # @param viewport [LiteRGSS::Viewport, nil]
    def initialize(viewport = nil)
      super(viewport)
      self.shader = Shader.create(:color_shader)
    end

    # Set the Sprite color
    # @param array [Array(Numeric, Numeric, Numeric, Numeric), LiteRGSS::Color] the color (values : 0~1.0)
    # @return [self]
    def color=(array)
      shader.set_float_uniform('color', array)
      return self
    end
    alias set_color color=
  end
end

# @deprecated Please use Sprite directly
class ShaderedSprite < Sprite

end

# Class simulating repeating texture
class Plane < Sprite
  # Shader of the Plane sprite
  SHADER = <<~ENDOFSHADER
    // Viewport tone (required)
    uniform vec4 tone;
    // Viewport color (required)
    uniform vec4 color;
    // Zoom configuration
    uniform vec2 zoom;
    // Origin configuration
    uniform vec2 origin;
    // Texture size configuration
    uniform vec2 textureSize;
    // Texture source
    uniform sampler2D texture;
    // Plane Texture (what's zoomed origined etc...)
    uniform sampler2D planeTexture;
    // Screen size
    uniform vec2 screenSize;
    // Gray scale transformation vector
    const vec3 lumaF = vec3(.299, .587, .114);
    // Main process
    void main()
    {
      // Coordinate on the screen in pixel
      vec2 screenCoord = gl_TexCoord[0].xy * screenSize;
      // Coordinaet in the texture in pixel (including zoom)
      vec2 bmpCoord = mod(origin + screenCoord / zoom, textureSize) / textureSize;
      vec4 frag = texture2D(planeTexture, bmpCoord);
      // Tone&Color process
      frag.rgb = mix(frag.rgb, color.rgb, color.a);
      float luma = dot(frag.rgb, lumaF);
      frag.rgb += tone.rgb;
      frag.rgb = mix(frag.rgb, vec3(luma), tone.w);
      frag.a *= gl_Color.a;
      // Result
      gl_FragColor = frag * texture2D(texture, gl_TexCoord[0].xy);
    }
  ENDOFSHADER

  # Get the real texture
  # @return [Texture]
  attr_reader :texture

  # Return the visibility of the plane
  # @return [Boolean]
  attr_reader :visible

  # Return the color of the plane /!\ this is unlinked set() won't change the color
  # @return [Color]
  attr_reader :color

  # Return the tone of the plane /!\ this is unlinked set() won't change the color
  # @return [Tone]
  attr_reader :tone

  # Return the blend type
  # @return [Integer]
  attr_reader :blend_type

  # Create a new plane
  # @param viewport [Viewport]
  def initialize(viewport)
    super(viewport)
    self.shader = Shader.new(SHADER)
    self.working_texture = Plane.texture
    self.tone = Tone.new(0, 0, 0, 0)
    self.color = Color.new(255, 255, 255, 0)
    @blend_type = 0
    @texture = nil
    @origin = [0, 0]
    self.visible = true
    set_origin(0, 0)
    @zoom = [1, 1]
    self.zoom = 1
    shader.set_float_uniform('screenSize', [width, height])
  end

  alias working_texture= bitmap=
  alias working_texture bitmap
  # Set the texture of the plane
  # @param texture [Texture]
  def texture=(texture)
    @texture = texture
    if texture.is_a?(LiteRGSS::Bitmap)
      shader.set_texture_uniform('planeTexture', texture)
      shader.set_float_uniform('textureSize', [texture.width, texture.height])
    end
    self.visible = @visible
  end
  alias bitmap= texture=
  alias bitmap texture

  # Set the visibility of the plane
  # @param visible [Boolean]
  def visible=(visible)
    super(visible && @texture.is_a?(LiteRGSS::Bitmap) ? true : false)
    @visible = visible
  end

  # Set the zoom of the Plane
  # @param zoom [Float]
  def zoom=(zoom)
    @zoom[0] = @zoom[1] = zoom
    shader.set_float_uniform('zoom', @zoom)
  end

  # Set the zoom_x of the Plane
  # @param zoom [Float]
  def zoom_x=(zoom)
    @zoom[0] = zoom
    shader.set_float_uniform('zoom', @zoom)
  end

  # Get the zoom_x of the Plane
  # @return [Float]
  def zoom_x
    @zoom[0]
  end

  # Set the zoom_y of the Plane
  # @param zoom [Float]
  def zoom_y=(zoom)
    @zoom[1] = zoom
    shader.set_float_uniform('zoom', @zoom)
  end

  # Get the zoom_y of the Plane
  # @return [Float]
  def zoom_y
    @zoom[1]
  end

  # Set the origin of the Plane
  # @param ox [Float]
  # @param oy [Float]
  def set_origin(ox, oy)
    @origin[0] = ox
    @origin[1] = oy
    shader.set_float_uniform('origin', @origin)
  end

  # Set the ox of the Plane
  # @param origin [Float]
  def ox=(origin)
    @origin[0] = origin
    shader.set_float_uniform('origin', @origin)
  end

  # Get the ox of the Plane
  # @return [Float]
  def ox
    @origin[0]
  end

  # Set the oy of the Plane
  # @param origin [Float]
  def oy=(origin)
    @origin[1] = origin
    shader.set_float_uniform('origin', @origin)
  end

  # Get the oy of the Plane
  # @return [Float]
  def oy
    @origin[1]
  end

  # Set the color of the Plane
  # @param color [Color]
  def color=(color)
    if color != @color && color.is_a?(Color)
      shader.set_float_uniform('color', color)
      @color ||= color
      @color.set(color.red, color.green, color.blue, color.alpha)
    end
  end

  # Set the tone of the Plane
  # @param tone [Tone]
  def tone=(tone)
    if tone != @tone && tone.is_a?(Tone)
      shader.set_float_uniform('tone', tone)
      @tone ||= tone
      @tone.set(tone.red, tone.green, tone.blue, tone.gray)
    end
  end

  # Set the blend type
  # @param blend_type [Integer]
  def blend_type=(blend_type)
    shader.blend_type = blend_type
    @blend_type = blend_type
  end

  class << self
    # Get the generic plane texture
    # @return [Texture]
    def texture
      if !@texture || @texture.disposed?
        @texture = Texture.new(Graphics.width, Graphics.height)
        image = Image.new(Graphics.width, Graphics.height)
        # TODO: revert to image.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(255, 255, 255, 255))
        # once liteRGSS2 gets fixed on this function
        Graphics.height.times do |y|
          image.fill_rect(0, y, Graphics.width, 1, Color.new(255, 255, 255, 255))
        end
        image.copy_to_bitmap(@texture)
        image.dispose
      end
      return @texture
    end
  end

  undef x
  undef x=
  undef y
  undef y=
  undef set_position
end

# Class that describes a text shown on the screen or inside a viewport
class Text < LiteRGSS::Text
end

# Class used to show a Window object on screen.
#
# A Window is an object that has a frame (built from #window_builder and #windowskin) and some contents that can be Sprites or Texts.
class Window < LiteRGSS::Window
end

# Class allowing to draw Shapes in a viewport
class Shape < LiteRGSS::Shape
end

# Class that allow to draw tiles on a row
class SpriteMap < LiteRGSS::SpriteMap
end
