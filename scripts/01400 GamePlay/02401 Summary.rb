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
    def initialize(pokemon, z = 1000, mode = :view, party = [pokemon], extend_data = nil)
      super(false, z * 10)
      @viewport = Viewport.create(:main, z)
      # @type [PFM::Pokemon]
      @pokemon = pokemon
      @mode = mode
      @party = party
      @index = mode == :skill ? 2 : 0
      @party_index = party.index(pokemon).to_i
      @skill_selected = -1
      @skill_index = -1
      @selecting_move = false
      @extend_data = extend_data
      create_sprites
      update_pokemon
    end

    private

    # Function creating all the sprites
    def create_sprites
      create_background
      create_uis
      create_top_ui
    end

    # Create the background
    def create_background
      @background = Sprite.new(@viewport).set_bitmap('team/Fond', :interface)
    end

    # Create the various UI
    def create_uis
      @uis = [
        UI::Summary_Memo.new(@viewport),
        UI::Summary_Stat.new(@viewport),
        UI::Summary_Skills.new(@viewport)
      ]
    end

    # Create the top UI
    def create_top_ui
      @top = UI::Summary_Top.new(@viewport)
    end

    # Update the UI visibility according to the index
    def update_ui_visibility
      @uis.each_with_index { |ui, index| ui.visible = index == @index }
    end

    # Update the Pokemon shown in the UIs
    def update_pokemon
      @uis.each { |ui| ui.data = @pokemon }
      @top.data = @pokemon
      update_ui_visibility
    end
  end
end
