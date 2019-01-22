#encoding: utf-8

module UI
  # Dex sprite that show the Pokemon location
  class DexWinMap < SpriteStack
    # Create a new dex win sprite
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :pokedex)
      push(6, 14, "WinMap")
      push(12 + 16, 107 + 16, nil, type: PokemonIconSprite)
      add_text(16, 18, 116, 16, _ext(9000, 19), color: 10)
    end
    # Change the data
    def data=(pokemon)
      super(pokemon)
      # update the map info with the pokemon X 49 ; Y 38
    end
  end
end
