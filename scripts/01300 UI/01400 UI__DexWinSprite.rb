#encoding: utf-8

module UI
  # Dex sprite that show the Pokemon sprite with its name
  class DexWinSprite < SpriteStack
    # Create a new dex win sprite
    def initialize(viewport)
      super(viewport, 3, 11, default_cache: :pokedex)
      push(0, 0, "WinSprite")
      push(60, 124, nil, type: PokemonFaceSprite)
      add_text(3, 6, 116, 19, :name_upper, 1, type: SymText, color: 10).bold = true
    end
  end
end
