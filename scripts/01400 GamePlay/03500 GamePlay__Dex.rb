#encoding: utf-8

module GamePlay
  # Class that shows the Pokedex
  class Dex < Base
    # Text format for the name
    NameStr="%03d - %s"
    # Text format for the weight
    WeightStr="Poids : %.2f Kg"
    # Text format for the height
    HeightStr="Taille : %.2f m"
    include UI
    # Create a new Pokedex interface
    # @param page_id [Integer, false] id of the page to show
    def initialize(page_id = false)
      super()
      @viewport = Viewport.create(:main, 50000)
      @background = Sprite.new(@viewport).set_bitmap("Fond", :pokedex)
      # Liste
      @list = Array.new(6) { |i| DexButton.new(@viewport, i) }
      @pokemonlist = PFM::Pokemon.new(0, 1)
      @arrow = Sprite.new(@viewport).set_bitmap("Arrow", :pokedex).set_position(127, 0)
      @arrowd = 1
      # Scrool
      @scrollbar = Sprite.new(@viewport).set_bitmap("Scroll", :pokedex)
        .set_position(309, 36)
      @scrollbut = Sprite.new(@viewport).set_bitmap("But_Scroll", :pokedex)
        .set_position(308, 41)
      # Frame
      @frame = Sprite.new(@viewport)
      @pokeface = DexWinSprite.new(@viewport)
      # Num generation
      @seen_got = DexSeenGot.new(@viewport)
      # Info
      @pokemon_info = DexWinInfo.new(@viewport)
      @pokemon_descr = Text.new(0, @viewport, 11, 153, 298, 16, nil.to_s).load_color(10)
      # Lieu
      @pokemon_zone = DexWinMap.new(@viewport)
      @state = page_id ? 1 : 0
      @page_id = page_id
      @ctrl = Array.new(4) { |i| DexCTRLButton.new(@viewport, i) }
      generate_selected_pokemon_array(page_id)
      generate_pokemon_object
      change_state(@state)
      Mouse.wheel = 0
    end

    # Update the background animation
    def update_background_animation
      @background.set_origin((@background.ox - 0.5) % 16, (@background.oy - 0.5) % 16)
    end

    # Update the interface
    def update
      update_background_animation
      update_arrow if @arrow.visible
      return unless super
      update_mouse_ctrl
      return action_A if Input.trigger?(:A)
      return action_X if Input.trigger?(:X)
      return action_Y if Input.trigger?(:Y)
      return action_B if Input.trigger?(:B)
      if @state == 0
        max_index = @selected_pokemons.size - 1
        if index_changed(:@index, :UP, :DOWN, max_index)
          update_index
        elsif index_changed!(:@index, :LEFT, :RIGHT, max_index)
          9.times { index_changed!(:@index, :LEFT, :RIGHT, max_index) }
          update_index
        elsif Mouse.wheel != 0
          @index = (@index - Mouse.wheel) % (max_index + 1)
          Mouse.wheel = 0
          update_index
        end
      end
    end

    # Update the arrow animation
    def update_arrow
      return if Graphics.frame_count % 15 != 0
      @arrow.x += @arrowd
      @arrowd = 1 if @arrow.x <= 127
      @arrowd = -1 if @arrow.x >= 129
    end

    # Update the index when changed
    def update_index
      @pokemon.id = @selected_pokemons[@index]
      @pokeface.data = @pokemon
      update_list(true)
    end

    # Action triggered when A is pressed
    def action_A
      return $game_system.se_play($data_system.buzzer_se) if @page_id
      $game_system.se_play($data_system.decision_se)
      change_state(@state + 1) if @state < 2
    end

    # Action triggered when B is pressed
    def action_B
      $game_system.se_play($data_system.decision_se)
      return @running = false if @state == 0 or @page_id
      change_state(@state - 1) if @state > 0
    end

    # Action triggered when X is pressed
    def action_X
      return if @state > 1 
      return $game_system.se_play($data_system.buzzer_se) if @page_id
      return $game_system.se_play($data_system.buzzer_se) #Non programmé
    end

    # Action triggered when Y is pressed
    def action_Y
      return if @state > 1
      return $game_system.se_play($data_system.buzzer_se) if @state == 0
      $game_system.cry_play(@pokemon.id) if @state == 1
    end

    # Array of actions to do according to the pressed button
    Actions = [:action_A, :action_X, :action_Y, :action_B]
    # Update the mouse interaction with the ctrl buttons
    def update_mouse_ctrl
      update_mouse_ctrl_buttons(@ctrl, Actions)
    end

    # Change the state of the Interface
    # @param state [Integer] the id of the state
    def change_state(state)
      @state = state
      @ctrl.each { |sp| sp.set_state(state) }
      @frame.set_bitmap(state == 1 ? "FrameInfos" : "Frame", :pokedex)
      @pokeface.data = @pokemon if(@pokeface.visible = state != 2)
      @arrow.visible = @seen_got.visible = state == 0
      @pokemon_info.visible = @pokemon_descr.visible = state == 1
    if @pokemon_descr.visible
        if $pokedex.has_captured?(@pokemon.id)
            @pokemon_descr.multiline_text = ::GameData::Pokemon.descr(@pokemon.id)
            @pokemon_info.data = @pokemon
        else
            @pokemon_descr.multiline_text = ""
            @pokemon_info.data = @pokemon
        end
    end
      @pokemon_zone.data = @pokemon if(@pokemon_zone.visible = state == 2)
      update_list(state == 0)
    end

    # Update the button list
    # @param visible [Boolean]
    def update_list(visible)
      @scrollbar.visible = @scrollbut.visible = visible
      if @selected_pokemons.size > 1
        @scrollbut.y = 41 + 150 * @index / (@selected_pokemons.size - 1)
      end
      base_index = calc_base_index
      @list.each_with_index do |el, i|
        next unless el.visible = visible
        pos = base_index + i
        id = @selected_pokemons[pos]
        next(el.visible = false) unless id and pos >= 0
        if el.selected = (pos == @index)
          @arrow.y = el.y + 11
        end
        @pokemonlist.id = id
        el.data = @pokemonlist
      end
    end

    # Calculate the base index of the list
    # @return [Integer]
    def calc_base_index
      return -1 if @selected_pokemons.size < 5
      if @index >= 2
        return @index - 2
      elsif @index < 2
        return -1
      end
    end

    # Generate the selected_pokemon array
    # @param page_id [Integer, false] see initialize
    def generate_selected_pokemon_array(page_id)
      if $pokedex.national?
        @selected_pokemons = []
        1.step($game_data_pokemon.size - 1) do |i|
          @selected_pokemons << i if $pokedex.has_seen?(i)
        end
      else
        selected_pokemons = []
        1.step($game_data_pokemon.size - 1) do |i|
          selected_pokemons << i if $pokedex.has_seen?(i) && ::GameData::Pokemon.id_bis(i) > 0
        end
        selected_pokemons.sort! { |a, b| ::GameData::Pokemon.id_bis(a) <=> ::GameData::Pokemon.id_bis(b) }
        @selected_pokemons = selected_pokemons
      end
      @selected_pokemons.compact!
      @selected_pokemons << 0 if @selected_pokemons.empty?
      # Index ajustment
      if page_id
        @index = @selected_pokemons.index(page_id)
        unless @index
          @selected_pokemons << page_id
          @index = @selected_pokemons.size - 1
        end
        # @index -= 1
      else
        @index = 0
      end
    end

    # Generate the Pokemon Object
    def generate_pokemon_object
      @pokemon = PFM::Pokemon.new(@selected_pokemons[@index].to_i,1)
      # Return the formated name for Pokedex
      # @return [String]
      def @pokemon.pokedex_name
        sprintf(GamePlay::Dex::NameStr, $pokedex.national? ? self.id : ::GameData::Pokemon.id_bis(self.id), self.name)
      end
      # Return the formated Specie for Pokedex
      # @return [String]
      def @pokemon.pokedex_species
        ::GameData::Pokemon.species(self.id)
      end
      # Return the formated weight for Pokedex
      # @return [String]
      def @pokemon.pokedex_weight
        format(_ext(9000, 70), self.weight)
      end
      # Return the formated height for Pokedex
      # @return [String]
      def @pokemon.pokedex_height
        format(_ext(9000, 71), self.height)
      end
    end

    # Dispose the interface
    def dispose
      super
      # @viewport.dispose
    end
  end
end
