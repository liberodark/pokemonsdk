#encoding: utf-8

module GamePlay
  class Sumary
    # Show the Informations of the Pokémon in the Sumary interface
    class B < UI::SpriteStack
      include UI
      def initialize(viewport, x = 0, y = 0, default_cache: :interface)
        super
        texts = _get_file(27)
        add_text(4,0,95,20, _ext(9000, 42), color: 8) # "Aptitudes", color: 8)
        add_text(198,42,95,20, _ext(9000, 43), color: 8) # "Capacités Combat", color: 8)
        add_text(19, 23, 66, 19, :given_name, type: SymText, color: 8)
        add_text(19, 39, 66, 19, :level_text2, type: SymText)
        push(85, 27, nil, type: GenderSprite)
        add_text(4, 55, 95, 18, _get(23,7), color: 8) #Objet
        add_text(4, 71, 95, 16, :item_name, type: SymText)
        4.times do |i|
          push_sprite(Skill.new(viewport, i))
        end
        add_text(4, 89, 55, 16, texts[15], 1,color: 8)
        add_text(7, 113, 52, 16, texts[18], color: 8)
        add_text(7, 129, 52, 16, texts[20], color: 8)
        add_text(7, 145, 52, 16, texts[26], color: 8)
        add_text(7, 161, 52, 16, texts[22], color: 8)
        add_text(7, 177, 52, 16, texts[24], color: 8)
        add_text(7, 193, 52, 16, _ext(9000, 44), color: 8) # "Cap. Spé.", color: 8)
        @hp_bar = push_sprite Bar.new(viewport, 59, 106, 
          RPG::Cache.interface("menu_pokemon_hp"), 50, 4, 14, 1, 6)
        add_text(61, 89, 65, 16, :hp_text,1, type: SymText)
        add_text(61, 113, 50, 16, :atk_basis, 2, type: SymText)
        add_text(61, 129, 50, 16, :dfe_basis, 2, type: SymText)
        add_text(61, 145, 50, 16, :spd_basis, 2, type: SymText)
        add_text(61, 161, 50, 16, :ats_basis, 2, type: SymText)
        add_text(61, 177, 50, 16, :dfs_basis, 2, type: SymText)
        add_text(61, 193, 65, 16, :ability_name, 1, type: SymText)
        add_text(7, 208, 148, 15, :ability_descr, type: SymMultilineText)
      end
      # Change the Pokemon shown
      # @param v [PFM::Pokemon]
      def data=(v)
        return self.visible = false unless v
        self.visible = true
        @hp_bar.rate = v.hp_rate
        super
      end
    end
  end
end
