# Module that allows a sprite to be quickly recenter (useful in a Battle::Visual3D scene)
module RecenterSprite

  # recenter a sprite according to the dimension of the window
  def recenter
    self.x += HALF_WIDTH
    self.y += HALF_HEIGHT
  end

  def add_position(offset_x, offset_y)
    self.x += offset_x
    self.y += offset_y
  end
end