#encoding: utf-8

module GamePlay
  class Sumary
    # Show the Rubans of the Pokémon in the Sumary interface
    class D < UI::SpriteStack
      include UI
      def initialize(viewport, x = 0, y = 0, default_cache: :interface)
        super
        texts = _get_file(27)
        add_text(4,0,95,20, _ext(9000, 45), color: 8) # "Concours", color: 8)
        add_text(198,42,95,20, _ext(9000, 46), color: 8) # "Ruban", color: 8)
        add_text(19, 23, 66, 19, :given_name, type: SymText, color: 8)
        add_text(19, 39, 66, 19, :level_text2, type: SymText)
        push(85, 27, nil, type: GenderSprite)
        add_text(4, 55, 95, 18, _get(23,7), color: 8) #Objet
        add_text(4, 71, 95, 16, :item_name, type: SymText)

      end
      # Change the Pokemon shown
      # @param v [PFM::Pokemon]
      def data=(v)
        return self.visible = false unless v
        self.visible = true
        super
      end
    end
  end
end
