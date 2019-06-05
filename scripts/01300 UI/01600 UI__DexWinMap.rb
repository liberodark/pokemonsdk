#encoding: utf-8

module UI
  # Dex sprite that show the Pokemon location
  class DexWinMap < SpriteStack
    MAP_ICON = '344'

    # Create a new dex win sprite
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :pokedex)
      # push(6, 14, "WinMap_Back")
      @pkm_icon = push(28, 123, nil, type: PokemonIconSprite)
      @item_icon = push(13, 106, nil)
      @location = add_text(10, 18, 132, 16, _ext(9000, 19), 1, color: 10)
      @region = add_text(150, 0, 150, 24, 'REGION', 2, color: 10)
      @region.bold = true
    end

    # Change the data
    def data=(pokemon)
      if pokemon == :map
        @pkm_icon.visible = false
        @item_icon.visible = true
        @item_icon.set_bitmap(MAP_ICON, :icon)
      elsif pokemon.is_a? PFM::Pokemon
        @pkm_icon.visible = true
        @item_icon.visible = false
        super(pokemon)
      end
    end

    # Set the location name
    # @param place [String] the name to display
    # @param color [Integer] the color code
    def set_location(place, color = 10)
      @location.multiline_text = place
      @location.load_color color
    end

    # Set the region name
    # @param place [String] the name to display
    # @param color [Integer] the color code
    def set_region(reg, color = 10)
      @region.multiline_text = reg.upcase
      @location.load_color color
    end
  end
end
