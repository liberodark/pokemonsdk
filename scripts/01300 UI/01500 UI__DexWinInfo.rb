#encoding: utf-8

module UI
  # Dex sprite that show the Pokemon infos
  class DexWinInfo < SpriteStack
    # Create a new dex win sprite
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :pokedex)
      push(131, 37, "WinInfos")
      push(139, 41, "Catch")
      add_text(160, 41, 116, 16, :pokedex_name, type: SymText, color: 10)
      add_text(140, 64, 116, 16, :pokedex_species, type: SymText)
      add_text(140, 104, 116, 16, :pokedex_weight, type: SymText)
      add_text(140, 124, 116, 16, :pokedex_height, type: SymText)
      push(156, 84, nil, true, type: Type1Sprite)
      push(243, 84, nil, true, type: Type2Sprite)
    end
    # Change the data
    def data=(pokemon)
      super(pokemon)
      @stack[1].visible = ($pokedex.has_captured?(pokemon.id))
    end
  end
end
