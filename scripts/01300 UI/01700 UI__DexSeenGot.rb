#encoding: utf-8

module UI
  # Dex sprite that show the Pokemon location
  class DexSeenGot < SpriteStack
    # Create a new dex win sprite
    def initialize(viewport)
      super(viewport, 0, 152, default_cache: :pokedex)
      push(0, 0, "WinNum")
      add_text(2, 0, 79, 26, _ext(9000, 20), color: 10).bold = true
      add_text(0, 0, 79, 26, :pokemon_seen, 2, type: SymText, color: 10)
      add_text(2, 28, 79, 26, _ext(9000, 21), color: 10).bold = true
      add_text(0, 28, 79, 26, :pokemon_captured, 2, type: SymText, color: 10)
      self.data = $pokedex
    end
  end
end
