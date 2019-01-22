#encoding: utf-8

module UI
  # Class that show the sprite of a key
  class KeyShortcut < Sprite
    # Create a new KeyShortcut sprite
    # @param viewport [LiteRGSS::Viewport]
    # @param key [Symbol] Input.trigger? argument
    # @param red [Boolean] pick the red texture instead of the blue texture
    def initialize(viewport, key, red = false)
      super(viewport)
      set_bitmap(red ? "Key_ShortRed" : "Key_Short", :pokedex)
      find_key(key)
    end
    # KeyIndex that holds the value of the Keyboard constants in the right order according to the texture
    KeyIndex = 
    [
      Keyboard::A, Keyboard::B, Keyboard::C, Keyboard::D, Keyboard::E, Keyboard::F, Keyboard::G, Keyboard::H, Keyboard::I, Keyboard::J,
      Keyboard::K, Keyboard::L, Keyboard::M, Keyboard::N, Keyboard::O, Keyboard::P, Keyboard::Q, Keyboard::R, Keyboard::S, Keyboard::T,
      Keyboard::U, Keyboard::V, Keyboard::W, Keyboard::X, Keyboard::Y, Keyboard::Z, Keyboard::Num0, Keyboard::Num1, Keyboard::Num2, Keyboard::Num3,
      Keyboard::Num4, Keyboard::Num5, Keyboard::Num6, Keyboard::Num7, Keyboard::Num8, Keyboard::Num9, Keyboard::Space, Keyboard::Backspace, Keyboard::Enter, Keyboard::LShift,
      Keyboard::LControl, Keyboard::LAlt, Keyboard::Escape, Keyboard::Left, Keyboard::Right, Keyboard::Up, Keyboard::Down
    ]
    # Find the key rect in the Sprite according to the input key requested
    # @param key [Symbol] the Virtual Input Key.
    def find_key(key)
      key_array = Input::Keys[key]
      key_array.each do |i|
        if id = KeyIndex.index(i)
          return set_rect_div(id % 10, id / 10, 10, 5)
        end
      end
      set_rect_div(9, 4, 10, 5) #A blank key
    end
  end
end
