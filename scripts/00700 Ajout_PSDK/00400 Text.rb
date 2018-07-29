#encoding: utf-8

# Class that helps to display text.
# 
# See https://psdk.pokemonworkshop.com/litergss/LiteRGSS/Text.html to get the other functions
class Text
  # Set a multiline text
  # @param value [String] Multiline text that should be ajusted to be display on multiple lines
  def multiline_text=(value)
    sw = self.text_width(" ") + 1 # /!\ 1 added for adjsutment, idk if correct or not. 
    x = 0
    max_width = self.width
    words = ""
    value.split(" ").each do |word|
      w = self.text_width(word)
      if(x + w > max_width)
        x = 0
        words << "\n"
      end
      words << word << " "
      x += (w + sw)
    end
    self.text = " " if words == self.text
    self.text = words
  end
end
