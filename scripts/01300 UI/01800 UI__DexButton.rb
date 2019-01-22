#encoding: utf-8

module UI
  # Dex sprite that show the Pokemon infos
  class DexButton < SpriteStack
    # Create a new dex button
    # @param viewport [LiteRGSS::Viewport]
    # @param i [Integer] index of the sprite in the viewport
    def initialize(viewport, i)
      super(viewport, 0, 0, default_cache: :pokedex)
      push(147, 62, "But_List")
      push(266, 71, "Catch") #> Should always be the second
      push(148 + 16, 61 + 16, nil, type: PokemonIconSprite)
      add_text(182, 63, 116, 16, :id_text3, type: SymText, color: 10)
      add_text(182, 78, 116, 16, :name, type: SymText, color: 10)
      push(147, 62, "But_ListShadow") #> Should always be the last
      @x = 147
      @y = 62
      self.set_position(i == 0 ? 147 : 163, @y - 40 + i * 40)
    end
    # Change the data
    def data=(pokemon)
      super(pokemon)
      @stack[1].visible = ($pokedex.has_captured?(pokemon.id))
    end
    # Set the button in selected state or not
    def selected=(value)
      @stack.last.visible = !value
      self.set_position(value ? 147 : 163, @y)
    end
  end
end
