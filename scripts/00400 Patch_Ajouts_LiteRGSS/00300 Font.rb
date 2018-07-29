#encoding: utf-8

# class that holds information about the font used to draw text on bitmaps
class Font
  # Name of the default PSDK font
  FONT_NAME = "Fonts/PokemonDS.ttf"
  font_exist = File.exist?(FONT_NAME)#Font.exist?("Pokemon DS")
  # The name of the default font
  FONT_POKEMON = font_exist ? FONT_NAME : "Fonts/VL-Gothic-Regular.ttf"#Font.default_name
  # the "normal" size of the default font
  FONT_SIZE = font_exist ? 26 : 25
  # the small size of the default font
  FONT_SMALL = font_exist ? 13 : 14
  # A constant that passive String#to_pokemon_number
  NoPokemonFont = !font_exist
  Fonts.load_font(0, FONT_POKEMON)
  Fonts.set_default_size(0, FONT_SMALL)
  Fonts.load_font(1, FONT_POKEMON)
  Fonts.set_default_size(1, FONT_SIZE)
  Fonts.load_font(20, "Fonts/PowerGreenSmall.ttf")
  Fonts.set_default_size(20, 11)
end
