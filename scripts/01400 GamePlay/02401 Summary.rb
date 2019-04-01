module GamePlay
  # Scene displaying the Summary of a Pokemon
  class Summary < Base
    # @return [Integer] Index of the choosen skill of the Pokemon
    attr_accessor :skill_selected
    # Create a new sumarry Interface
    # @param pokemon [PFM::Pokemon] Pokemon currently shown
    # @param z [Integer] Z index of the UIs
    # @param mode [Symbol] :view if it's about viewing a Pokemon, :skill if it's about choosing the skill of the Pokemon
    # @param party [Array<PFM::Pokemon>] the party (allowing to switch Pokemon)
    # @param extend_data [Hash, nil] the extend data information when we are in :skill mode
    def initialize(pokemon, z = 1000, mode = :view, party = [], extend_data = nil)
      super(false, z * 10)
      @viewport = Viewport.create(:main, z)
      # @type [PFM::Pokemon]
      @pokemon = pokemon
      @mode = mode
      @party = party
      @index = 1 # < test (mode == :skill ? 2 : 0)
      @skill_selected = -1
      @skill_index = 0
      @extend_data = extend_data
      @uis = [
        UI::Summary_Memo.new(@viewport),
        UI::Summary_Stat.new(@viewport),
        UI::Summary_Skills.new(@viewport)
      ]
      @top = UI::Summary_Top.new(@viewport)
      update_ui_visibility
      update_pokemon
    end

    # Update the UI visibility according to the index
    def update_ui_visibility
      @uis.each_with_index { |ui, index| ui.visible = index == @index }
    end

    # Update the Pokemon shown in the UIs
    def update_pokemon
      @uis.each { |ui| ui.data = @pokemon }
      @top.data = @pokemon
    end
  end
end

module UI
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

module UI
  class Summary_Stat < SpriteStack
    # Show the IV ?
    SHOW_IV = true
    # Show the EV ?
    SHOW_EV = true
    # Create a new Stat UI for the summary
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :interface)
      push(0, 0, 'summary/stats')
      init_stats
      ability_text = add_text(13, 138, 100, 16, _get(33, 142) + ': ')
      @ability_name = add_text(13 + ability_text.real_width, 138, 294, 16, :ability_name, type: SymText, color: 1)
      @ability_descr = add_text(13, 138 + 16, 294, 16, :ability_descr, type: SymMultilineText)
    end

    # Set the Pokemon shown by the UI
    # @param pokemon [PFM::Pokemon]
    def data=(pokemon)
      super
      @nature_text.text = PFM::Text.parse(28, pokemon.nature_id)
      # Load the stat color according to the nature
      nature = pokemon.nature
      1.upto(5) do |i|
        color = nature[i] < 100 ? 23 : 22
        color = 0 if nature[i] == 100
        @stat_name_texts[i - 1].load_color(color)
      end
    end

    # Init the stat texts
    def init_stats
      texts = _get_file(27)
      # --- Static part ---
      @nature_text = add_text(114, 19, 60, 16, '') # Nature
      @stat_name_texts = []
      add_text(114, 19 + 16, 60, 16, texts[15]) # HP
      @stat_name_texts << add_text(114, 19 + 32, 60, 16, texts[18]) # Attack
      @stat_name_texts << add_text(114, 19 + 48, 60, 16, texts[20]) # Defense
      @stat_name_texts << add_text(114, 19 + 64, 120, 16, texts[26]) # Speed
      @stat_name_texts << add_text(114, 19 + 80, 120, 16, texts[22]) # Attack Spe
      @stat_name_texts << add_text(114, 19 + 96, 95, 16, texts[24]) # Defense Spe
      # --- Data part ---
      add_text(114, 19 + 16, 95, 16, :hp_text, 2, type: SymText, color: 1)
      add_text(114, 19 + 32, 95, 16, :atk_basis, 2, type: SymText, color: 1)
      add_text(114, 19 + 48, 95, 16, :dfe_basis, 2, type: SymText, color: 1)
      add_text(114, 19 + 64, 95, 16, :spd_basis, 2, type: SymText, color: 1)
      add_text(114, 19 + 80, 95, 16, :ats_basis, 2, type: SymText, color: 1)
      add_text(114, 19 + 96, 95, 16, :dfs_basis, 2, type: SymText, color: 1)
      init_ev_iv
    end

    # Init the ev/iv texts
    def init_ev_iv
      offset = 102
      # --- IV part ---
      if SHOW_IV
        add_text(114 + offset, 19 + 16, 95, 16, :iv_hp_text, type: SymText)
        add_text(114 + offset, 19 + 32, 95, 16, :iv_atk_text, type: SymText)
        add_text(114 + offset, 19 + 48, 95, 16, :iv_dfe_text, type: SymText)
        add_text(114 + offset, 19 + 64, 95, 16, :iv_spd_text, type: SymText)
        add_text(114 + offset, 19 + 80, 95, 16, :iv_ats_text, type: SymText)
        add_text(114 + offset, 19 + 96, 95, 16, :iv_dfs_text, type: SymText)
        offset += 44
      end
      # --- EV part ---
      if SHOW_EV
        add_text(114 + offset, 19 + 16, 95, 16, :ev_hp_text, type: SymText)
        add_text(114 + offset, 19 + 32, 95, 16, :ev_atk_text, type: SymText)
        add_text(114 + offset, 19 + 48, 95, 16, :ev_dfe_text, type: SymText)
        add_text(114 + offset, 19 + 64, 95, 16, :ev_spd_text, type: SymText)
        add_text(114 + offset, 19 + 80, 95, 16, :ev_ats_text, type: SymText)
        add_text(114 + offset, 19 + 96, 95, 16, :ev_dfs_text, type: SymText)
      end
    end
  end
end

module UI
  class Summary_Skills < SpriteStack
    # Create a new Skills UI for the summary
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :interface)
      push(0, 0, 'summary/moves')
    end
  end
end

module UI
  class Summary_Top < SpriteStack
    NO_GENDER = [29, 32]
    # Create a new Memo UI for the summary
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :interface)
      push(55, 119, nil, type: PokemonFaceSprite)
      @name = add_text(11, 8, 100, 16, :given_name, type: SymText, color: 9)
      @gender = push(101, 10, nil, type: GenderSprite)
      @item = push(72 + 6, 88 + 16, nil, type: RealHoldSprite)
      @ball = push(107, 11, nil, ox: 16, oy: 16)
      # Last sprite
      push(0, 214, 'summary/button_hub')
    end

    # Set the Pokemon shown
    # @param pokemon [PFM::Pokemon]
    def data=(pokemon)
      super
      @gender.ox = 88 - @name.real_width
      @gender.visible = false if NO_GENDER.include?(pokemon.id) || pokemon.egg?
      @item.visible = false if pokemon.egg?
      @ball.set_bitmap(GameData::Item.icon(pokemon.captured_with), :icon)
    end
  end
end
