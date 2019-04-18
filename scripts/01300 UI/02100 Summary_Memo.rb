module UI
  # UI part displaying the "Memo" of the Pokemon in the Summary
  class Summary_Memo < SpriteStack
    # Create a new Memo UI for the summary
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :interface)
      push(0, 0, 'summary/memo')
      @invisible_if_egg = []
      init_memo
      @text_info = add_text(13, 138, 294, 16, '')
    end

    # Set an object inivisible if the Pokemon is an egg
    # @param object [#visible=] the object that is invisible if the Pokemon is an egg
    def no_egg(object)
      @invisible_if_egg << object
      return object
    end

    # Define the pokemon shown by this UI
    # @param pokemon [PFM::Pokemon]
    def data=(pokemon)
      if (self.visible = !pokemon.nil?)
        super
        @invisible_if_egg.each { |sprite| sprite.visible = false } if pokemon.egg?
        @level_text.x = @level_value.x + @level_value.width - @level_value.real_width -
                        @level_text.real_width - 2
        load_text_info(pokemon)
      end
    end

    # Initialize the Memo part
    def init_memo
      texts = _get_file(27)
      # --- Static part ---
      add_text(114, 19, 60, 16, texts[2]) # Nom
      no_egg add_text(114, 19 + 16, 60, 16, texts[0]) # NoPokedex
      @level_text = no_egg(add_text(114 + 97, 19 + 16, 60, 16, texts[29])) # Level
      no_egg add_text(114, 19 + 32, 60, 16, texts[3]) # Type
      no_egg add_text(114, 19 + 48, 60, 16, texts[8]) # DO
      no_egg add_text(114 + 97, 19 + 48, 60, 16, texts[9]) # Numero id
      no_egg add_text(114, 19 + 64, 120, 16, texts[10]) # Pt exp
      no_egg add_text(114, 19 + 80, 120, 16, texts[12]) # Next lvl
      no_egg add_text(114, 19 + 96, 95, 16, _get(23, 7)) # Objet
      # --- Data part ---
      add_text(114, 19, 194, 16, :name, 2, type: SymText, color: 1)
      no_egg add_text(114, 19 + 16, 95, 16, :id_text, 2, type: SymText, color: 1)
      @level_value = no_egg(add_text(114 + 97, 19 + 16, 95, 16, :level_text, 2, type: SymText, color: 1))
      no_egg push(241, 19 + 34, nil, type: Type1Sprite)
      no_egg push(275, 19 + 34, nil, type: Type2Sprite)
      no_egg add_text(114, 19 + 48, 90, 16, :trainer_name, 2, type: SymText, color: 1)
      no_egg add_text(114 + 97, 19 + 48, 97, 16, :trainer_id_text, 2, type: SymText, color: 1)
      no_egg add_text(114, 19 + 64, 194, 16, :exp_text, 2, type: SymText, color: 1)
      no_egg add_text(114, 19 + 80, 194, 16, :exp_remaining_text, 2, type: SymText, color: 1)
      no_egg add_text(114, 19 + 96, 194, 16, :item_name, 2, type: SymText, color: 1)
    end

    # Load the text info
    # @param pokemon [PFM::Pokemon]
    def load_text_info(pokemon)
      return load_egg_text_info(pokemon) if pokemon.egg?
      time = Time.new
      time -= (time.to_i - 1)
      time += pokemon.captured_at
      hash = {
        '[VAR NUM3(0003)]' => pokemon.captured_level.to_s,
        '[VAR NUM2(0002)]' => time.strftime('%d'),
        '[VAR NUM2(0001)]' => time.strftime('%m'),
        '[VAR NUM2(0000)]' => time.strftime('%y'),
        '[VAR LOCATION(0004)]' => pokemon.captured_zone_name
      }
      text = _parse(28, 25, hash).gsub(/([0-9.]) ([a-z]+ *)\:/i) { "#{$1} \n#{$2}:" }
      text.gsub!('Level', "\nLevel") if $options.language == 'en'
      @text_info.multiline_text = text
    end

    # Load the text info when it's an egg
    # @param pokemon [PFM::Pokemon]
    def load_egg_text_info(pokemon)
      if pokemon.step_remaining > 10_240
        text = _get(28, 89)
      elsif pokemon.step_remaining > 2_560
        text = _get(28, 88)
      elsif pokemon.step_remaining > 1_280
        text = _get(28, 87)
      else
        text = _get(28, 86)
      end
      @text_info.multiline_text = text.gsub(/([^.]\.|\?|\!) /) { "#{$1} \n" }
    end
  end
end
