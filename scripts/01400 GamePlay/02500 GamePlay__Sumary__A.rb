#encoding: utf-8

module GamePlay
  # Pokemon Sumary interface
  class Sumary
    # Show the Informations of the Pokémon in the Sumary interface
    class A < UI::SpriteStack
      include UI
      def initialize(viewport, x = 0, y = 0, default_cache: :interface)
        super
        @egg_stack = SpriteStack.new(viewport, x, y, default_cache:  default_cache)
        @egg_stack.add_text(4, 0, 95, 20, _ext(9000, 40), color: 8) # "Mémo Dresseur", color: 8)
        @egg_stack.add_text(198, 42, 95, 20, _ext(9000, 41), color: 8) # "Infos Pokémon", color: 8)
        @egg_stack.add_text(19, 23, 66, 19, _get(0, 0), color: 8)
        @egg_phrase = @egg_stack.add_text(6, 88, 123, 16, nil.to_s)
        texts = _get_file(27)
        add_text(4, 0, 95, 20, _ext(9000, 40), color: 8)
        add_text(198, 42, 95, 20, _ext(9000, 41), color: 8)
        add_text(19, 23, 66, 19, :given_name, type: SymText, color: 8)
        add_text(19, 39, 66, 19, :level_text2, type: SymText)
        push(85, 27, nil, type: GenderSprite)
        add_text(4, 55, 95, 18, _get(23, 7), color: 8)
        add_text(4, 71, 95, 16, :item_name, type: SymText)
        add_text(4, 88, 132, 16, :nature_text, type: SymText, color: 1)
        @pokemon_phrase = add_text(4, 121, 132, 16, nil.to_s)
        add_text(149, 89, 60, 16, texts[0], color: 8) #N°Pokédex
        add_text(149, 105, 60, 16, texts[2], color: 8) #Nom
        add_text(149, 121, 60, 16, texts[3], color: 8) #Type
        add_text(149, 137, 60, 16, texts[8], color: 8) #DO
        add_text(149, 153, 60, 16, texts[9], color: 8) #Numéro id
        add_text(149, 169, 120, 16, texts[10], color: 8) #Pt exp
        add_text(149, 201, 120, 16, texts[12], color: 8) #Next lvl
        add_text(211, 89, 68, 16, :id_text, 2, type: SymText)
        add_text(211, 105, 68, 16, :name, 2, type: SymText)
        push(215, 122, nil, type: Type1Sprite)
        push(248, 122, nil, type: Type2Sprite)
        add_text(211, 137, 68, 16, :trainer_name, 2, type: SymText)
        add_text(211, 153, 68, 16, :trainer_id_text, 2, type: SymText)
        add_text(211, 185, 68, 16, :exp_text, 2, type: SymText)
        add_text(211, 217, 68, 16, :exp_remaining_text, 2, type: SymText)
        @exp_bar = push_sprite Bar.new(viewport, 213, 235, RPG::Cache.interface("battlebar_exp"),93, 2, 0, 0, 1)
      end
      # Change the Pokemon shown
      # @param v [PFM::Pokemon]
      def data=(v)
        return self.visible = false unless v
        if v.egg?
          @egg_stack.visible = true
          update_egg_phrase(v)
          self.each { |sprite| sprite.visible = false }
        else
          @egg_stack.visible = false
          self.each { |sprite| sprite.visible = true }
          update_pokemon_phrase(v)
          @exp_bar.rate = v.exp_rate
          super
        end
      end
      # Update the egg phrase
      # @param pokemon [PFM::Pokemon]
      def update_egg_phrase(pokemon)
        if(pokemon.step_remaining>10240)
          @egg_phrase.multiline_text = _get(28,89)
        elsif(pokemon.step_remaining>2560)
          @egg_phrase.multiline_text = _get(28,88)
        elsif(pokemon.step_remaining>1280)
          @egg_phrase.multiline_text = _get(28,87)
        else
          @egg_phrase.multiline_text = _get(28,86)
        end
      end
      # Update the Pokemon phrase
      # @param pokemon [PFM::Pokemon]
      def update_pokemon_phrase(pokemon)
        time = Time.new
        time -= (time.to_i-1)
        time += pokemon.captured_at
        @pokemon_phrase.multiline_text = _parse(28,25, "[VAR NUM3(0003)]" => pokemon.captured_level.to_s,
        "[VAR NUM2(0002)]" => time.strftime("%d"),
        "[VAR NUM2(0001)]" => time.strftime("%m"),
        "[VAR NUM2(0000)]" => time.strftime("%y"),
        "[VAR LOCATION(0004)]" => pokemon.captured_zone_name)
      end
      # Change the visibility of the Informations
      # @param v [Boolean]
      def visible=(v)
        super
        @egg_stack.visible = v
      end
    end
  end
end
