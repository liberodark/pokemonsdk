#encoding: utf-8

class Sprite
  # Detect if the mouse is in the sprite (without rotation and stuff like that)
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Boolean]
  # @author Nuri Yuri
  def simple_mouse_in?(mx = Mouse.x, my = Mouse.y)
    if self.viewport
      rect = self.viewport.rect
      mx -= rect.x
      my -= rect.y
      return false if mx >= rect.width or my >= rect.height
    end
    bx = self.x
    by = self.y
    return false if mx < bx or my < by
    bx += self.src_rect.width
    by += self.src_rect.height
    return false if mx >= bx or my >= by
    true
  end
  # Detect if the mouse is in the sprite (without rotation)
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Boolean]
  # @author Nuri Yuri
  def mouse_in?(mx = Mouse.x, my = Mouse.y)
    if self.viewport
      rect = self.viewport.rect
      mx -= rect.x
      my -= rect.y
      return false if mx >= rect.width or my >= rect.height
    end
    bx = self.x - self.ox * (zx = self.zoom_x)
    by = self.y - self.oy * (zy = self.zoom_y)
    return false if mx < bx or my < by
    bx += self.src_rect.width * zx
    by += self.src_rect.height * zy
    return false if mx >= bx or my >= by
    true
  end
  # Convert mouse coordinate on the screen to mouse coordinates on the sprite
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Array(Integer, Integer)] the mouse coordinates on the sprite
  # @author Nuri Yuri
  def translate_mouse_coords(mx = Mouse.x, my = Mouse.y)
    if self.viewport
      rect = self.viewport.rect
      mx -= rect.x
      my -= rect.y
    end
    mx -= self.x
    my -= self.y
    rect = self.src_rect
    mx += rect.x
    my += rect.y
    return mx, my
  end
end

class Text
  # Detect if the mouse is in the sprite (without rotation and stuff like that)
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Boolean]
  # @author Nuri Yuri
  def simple_mouse_in?(mx = Mouse.x, my = Mouse.y)
    if self.viewport
      rect = self.viewport.rect
      mx -= rect.x
      my -= rect.y
      return false if mx >= rect.width or my >= rect.height
    end
    bx = self.x
    by = self.y
    return false if mx < bx or my < by
    bx += self.width
    by += self.height
    return false if mx >= bx or my >= by
    true
  end
  # Convert mouse coordinate on the screen to mouse coordinates on the sprite
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Array(Integer, Integer)] the mouse coordinates on the sprite
  # @author Nuri Yuri
  def translate_mouse_coords(mx = Mouse.x, my = Mouse.y)
    if self.viewport
      rect = self.viewport.rect
      mx -= rect.x
      my -= rect.y
    end
    mx -= self.x
    my -= self.y
    return mx, my
  end
end

class Game_Window
  # Detect if the mouse is in the sprite (without rotation and stuff like that)
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Boolean]
  # @author Nuri Yuri
  def simple_mouse_in?(mx = Mouse.x, my = Mouse.y)
    @window.simple_mouse_in?(mx, my)
  end
  # Convert mouse coordinate on the screen to mouse coordinates on the sprite
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Array(Integer, Integer)] the mouse coordinates on the sprite
  # @author Nuri Yuri
  def translate_mouse_coords(mx = Mouse.x, my = Mouse.y)
    @window.translate_mouse_coords(mx, my)
  end
end

class Viewport
  # Detect if the mouse is in the sprite (without rotation and stuff like that)
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Boolean]
  # @author Nuri Yuri
  def simple_mouse_in?(mx = Mouse.x, my = Mouse.y)
    _rc = self.rect
    if _rc.x <= mx and (_rc.x + _rc.width) > mx and _rc.y <= my and (_rc.y + _rc.height) > mx
      return true
    end
    return false
  end
  # Convert mouse coordinate on the screen to mouse coordinates on the sprite
  # @param mx [Integer] the mouse x position on the screen
  # @param my [Integer] the mouse y position on the screen
  # @return [Array(Integer, Integer)] the mouse coordinates on the sprite
  # @author Nuri Yuri
  def translate_mouse_coords(mx = Mouse.x, my = Mouse.y)
    _rc = self.rect
    return mx - _rc.x, my - _rc.y
  end
end
