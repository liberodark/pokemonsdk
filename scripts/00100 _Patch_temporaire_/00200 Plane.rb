#encoding: utf-8

# Class that helps to display a mosaic
class Plane
  # Get ox
  # @return [Numeric]
  attr_reader :ox
  # Get oy
  # @return [Numeric]
  attr_reader :oy
  # Get opacity
  # @return [Integer]
  attr_reader :opacity
  # Get visibility
  # @return [Boolean]
  attr_reader :visible
  # Get Bitmap
  # @return [Bitmap, nil]
  attr_reader :bitmap
  # Get z
  # @return [Integer]
  attr_reader :z
  # Get zoom_x
  # @return [Numeric]
  attr_reader :zoom_x
  # Get zoom_y
  # @return [Numeric]
  attr_reader :zoom_y
  # Get Viewport
  # @return [LiteRGSS::Viewport]
  attr_reader :viewport
  # Create a new Plane
  # @param viewport [LiteRGSS::Viewport]
  def initialize(viewport)
    raise LiteRGSS::Error, "Plane requires a viewport to be displayed." unless viewport.is_a?(LiteRGSS::Viewport)
    @viewport = viewport
    @z = @ox = @oy = 0
    @opacity = 255
    @zoom_x = @zoom_y = 1.0
    @visible = true
    @bitmap = nil
    @sprites = []
    @width = 1
    @height = 1
    @disposed = false
    @class = Sprite #< To allow specific Plane
  end
  # Set ox
  # @param v [Numeric]
  def ox=(v)
    raise TypeError unless v.is_a?(Numeric)
    @ox = v
    v %= @width
    each_sprite { |sprite| sprite.ox = v }
  end
  # Set oy
  # @param v [Numeric]
  def oy=(v)
    raise TypeError unless v.is_a?(Numeric)
    @oy = v
    v %= @height
    each_sprite { |sprite| sprite.oy = v }
  end
  # Set z
  # @param v [Integer]
  def z=(v)
    raise TypeError unless v.is_a?(Integer)
    @z = v
    each_sprite { |sprite| sprite.z = v }
  end
  # Set the origin
  # @param _ox [Numeric]
  # @param _oy [Numeric]
  def set_origin(_ox, _oy)
    raise TypeError unless _ox.is_a?(Numeric) and _oy.is_a?(Numeric)
    @ox = _ox
    @oy = _oy
    _ox %= @width
    _oy %= @height
    each_sprite { |sprite| sprite.set_origin(_ox, _oy) }
  end
  # Set the opacity
  # @param v [Integer]
  def opacity=(v)
    raise TypeError unless v.is_a?(Integer)
    @opacity = (v > 255 ? 255 : (v < 0 ? 0 : v))
    each_sprite { |sprite| sprite.opacity = v }
  end
  # Set the zoom_x
  # @param v [Numeric]
  def zoom_x=(v)
    raise TypeError unless v.is_a?(Numeric)
    return if v == @zoom_x
    @zoom_x = v.abs
    update_geometry
  end
  # Set the zoom_y
  # @param v [Numeric]
  def zoom_y=(v)
    raise TypeError unless v.is_a?(Numeric)
    return if v == @zoom_y
    @zoom_y = v.abs
    update_geometry
  end
  # Set the zoom
  # @param v [Numeric]
  def zoom=(v)
    raise TypeError unless v.is_a?(Numeric)
    return if v == @zoom_x and v == @zoom_y
    @zoom_y = @zoom_x = v.abs
    update_geometry
  end
  # Is the Plane disposed
  # @return [Boolean]
  def disposed?
    return @disposed
  end
  # Dispose the Plane
  def dispose
    return if @disposed
    each_sprite { |sprite| sprite.dispose }
    @sprites.clear
    @disposed = true
  end
  # Change the bitmap
  # @param v [LiteRGSS::Bitmap]
  def bitmap=(v)
    return if @disposed
    if v == nil
      @bitmap = nil
      dispose
      return @disposed = false
    end
    raise TypeError unless v.is_a?(LiteRGSS::Bitmap)
    @bitmap = v
    @width = v.width
    @height = v.height
    update_geometry
  end
  private
  # Iterate something on each sprite
  def each_sprite
    @sprites.each do |row|
      row.each do |sprite|
        yield(sprite)
      end
    end
  end
  # Update the Geometry
  def update_geometry
    return unless bmp = @bitmap
    v = @viewport
    vw = v.rect.width
    vh = v.rect.height
    w = @width * @zoom_x
    h = @height * @zoom_y
    nb_sprite_x = (vw / w).round + 2
    nb_sprite_y = (vh / h).round + 2
    if nb_sprite_x * nb_sprite_y >= 1000
      raise LiteRGSS::Error, "Your plane bitmap is a bit too small for the given configuration."
    end
    puts "#{nb_sprite_x}, #{nb_sprite_y}"
    _ox = @ox % @width
    _oy = @oy % @height
    _zx = @zoom_x
    _zy = @zoom_y
    _z = @z
    _opacity = @opacity
    _visible = @visible
    each_sprite { |sprite| sprite.dispose }
    @sprites.clear
    _class = @class
    @sprites = Array.new(nb_sprite_y) do |y|
      _y = y * h
      Array.new(nb_sprite_x) do |x|
        sp = _class.new(v).set_position(x * w, _y).set_origin(_ox, _oy)
        sp.z = _z
        sp.opacity = _opacity
        sp.visible = _visible
        sp.zoom_x = _zx
        sp.zoom_y = _zy
        sp.bitmap = bmp
        next(sp)
      end
    end
    v.sort_z
  end
end
