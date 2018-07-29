#encoding: utf-8

module UI
  # Control button of the pokedex
  class DexCTRLButton < SpriteStack
    # Array of button coordinates
    Coordinates = [[3, 219], [83, 219], [163, 219], [243, 219]]
    # Array of Key to press
    Keys = [:A, :X, :Y, :B]
    # Texts
    Texts = [[": infos", ": rechercher", ": alt. liste", ": retour"],
      [": habitat", ": formes", ": cri", ": retour"],
      nil,
      [": infos", ": éch. Pkmn", ": éch. objet", ": retour"]] #> Team buttons
    Texts[2] = Texts.first
    # Create a new Button
    # @param viewport [LiteRGSS::Viewport]
    # @param id [Integer] the id of the button
    def initialize(viewport, id)
      super(viewport, *Coordinates[id], default_cache: :pokedex)
      push(0, 0, "Buttons").set_rect_div(id == 3 ? 1 : 0, 0, 2, 2)
      @stack.first.src_rect.x += 1 if id == 3
      push(0, 1, nil, Keys[id], id == 3, type: KeyShortcut)
      @font_id = 20
      add_text(17, 3, 51, 13, Texts[0][id], color: id == 3 ? 21 : 20)
      @id = id
    end
    # Change the button state
    # @param id_state [Integer] the state of the DEX scene (0, 1, 2)
    def set_state(id_state)
      if id_state >= 2 and @id > 0 and @id < 3
        return self.visible = false
      end
      self.visible = true if @id > 0 and @id < 3
      @stack.last.text = Texts[id_state][@id]
      return self
    end
    # Set the button pressed
    # @param pressed [Boolean] if the button is pressed or not
    def set_press(pressed)
      @stack.first.set_rect_div(@id == 3 ? 1 : 0, pressed ? 1 : 0, 2, 2)
      @stack.first.src_rect.x += 1 if @id == 3
      @stack.first.src_rect.y += 1 if pressed
    end
  end
  # Control button of the Team
  class TeamCTRLButton < DexCTRLButton
    # Create a new Button
    # @param viewport [LiteRGSS::Viewport]
    # @param id [Integer] the id of the button
    def initialize(viewport, id)
      super
      set_state(3)
    end
    # Change the button state
    # @param id_state [Integer] the state of the Team scene (3)
    def set_state(id_state)
      if id_state != 3 and @id > 0 and @id < 3
        return self.visible = false
      end
      self.visible = true if @id > 0 and @id < 3
      @stack.last.text = Texts[id_state][@id]
      return self
    end
  end
end
