module UI
  # Window utility allowing to make Window easilly
  class Window < ::Window
    DEFAULT_SKIN = 'message'
    # Create a new Window
    # @param viewport [Viewport] viewport where the window is shown
    # @param x [Integer] X position of the window
    # @param y [Integer] Y position of the window
    # @param width [Integer] Width of the window
    # @param height [Integer] Height of the window
    # @param skin [String] Windowskin used to display the window
    def initialize(viewport, x = 2, y = 2, width = 316, height = 48, skin: DEFAULT_SKIN)
      super(viewport)
      lock
      set_position(x, y)
      set_size(width, height)
      self.windowskin = RPG::Cache.windowskin(skin)
      self.window_builder = current_window_builder(skin)
      unlock
    end

    # Add a text to the window
    # @see https://psdk.pokemonworkshop.fr/yard/UI/SpriteStack.html#add_text-instance_method UI::SpriteStack#add_text
    def add_text(x, y, width, height, str, align = 0, outlinesize = Text::Util::DEFAULT_OUTLINE_SIZE, type: Text, color: 0)
      sprite_stack.add_text(x, y, width, height, str, align, outlinesize, type: type, color: color)
    end

    # Add a text line to the window
    # @see https://psdk.pokemonworkshop.fr/yard/UI/SpriteStack.html#add_line-instance_method UI::SpriteStack#add_line
    def add_line(line_index, str, align = 0, outlinesize = Text::Util::DEFAULT_OUTLINE_SIZE, type: Text, color: nil, dx: 0)
      sprite_stack.add_line(line_index, str, align, outlinesize, type: type, color: color, dx: dx)
    end

    # Push a sprite to the window
    # @see https://psdk.pokemonworkshop.fr/yard/UI/SpriteStack.html#push-instance_method UI::SpriteStack#push
    def push(x, y, bmp, *args, rect: nil, type: LiteRGSS::Sprite, ox: 0, oy: 0)
      sprite_stack.push(x, y, bmp, *args, rect: rect, type: type, ox: ox, oy: oy)
    end

    # Return the stack of the window if any
    # @return [Array]
    def stack
      return (@stack&.stack || [])
    end

    # Return the sprite stack used by the window
    # @return [SpriteStack]
    def sprite_stack
      @stack ||= SpriteStack.new(self)
    end

    # Load the cursor
    def load_cursor
      cursor_rect.set(0, 0, 16, 16)
      self.cursorskin = RPG::Cache.windowskin('cursor')
    end

    private

    # Retrieve the current window_builder
    # @param skin [String]
    # @return [Array]
    def current_window_builder(skin)
      return ::GameData::Windows::MessageHGSS if skin[0, 2].casecmp?('m_') # SkinHGSS
      ::GameData::Windows::MessageWindow # Skin PSDK
    end
  end
end
