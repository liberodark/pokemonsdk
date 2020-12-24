module BattleUI
  # Class that allow to choose the skill of the Pokemon
  #
  #
  # The object tells the player validated on #validated? and the result is stored inside #result
  #
  # The object should be updated through #update otherwise no validation is possible
  #
  # When result was taken, the scene should call #reset to undo the validated state
  class SkillChoice < UI::SpriteStack
    # Offset X of the cursor compared to the element it shows
    CURSOR_OFFSET_X = -10
    # Offset Y of the cursor compared to the element it shows
    CURSOR_OFFSET_Y = 6
    # Coordinate of each buttons
    BUTTON_COORDINATE = [[198, 124], [198, 153], [198, 182], [198, 211]]
    # The selected move
    # @return [Battle::Move, :cancel]
    attr_reader :result
    # The pokemon the player choosed a move
    # @return [PFM::PokemonBattler]
    attr_reader :pokemon
    # Get the index of the choice
    # @return [Integer]
    attr_reader :index
    # Create a new SkillChoice UI
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    def initialize(viewport, scene)
      super(viewport)
      @scene = scene
      @index = 0
      # List of last index according to the pokemon that was used
      # @type [Hash{ PFM::PokemonBattler => Integer }]
      @last_indexes = {}
      create_sprites
      self.visible = false
    end

    # Update the window cursor
    def update
      return if validated?
      return special_validate if special_validating?
      return if @move_description.visible
      return validate if validating?
      return cancel if canceling?

      last_index = @index
      update_key_index
      update_mouse_index
      if last_index != @index
        update_cursor
        @info.data = @pokemon
      end
    end

    # Tell if the player made a choice
    # @return [Boolean]
    def validated?
      !@result.nil?
    end

    # Reset the Skill choice
    # @param pokemon [PFM::PokemonBattler]
    def reset(pokemon)
      @pokemon = pokemon
      @mega_enabled = false
      self.data = pokemon
      update_cursor(true)
    end

    private

    def create_sprites
      create_buttons
      create_info
      create_special_buttons
      create_cursor
      create_move_description
    end

    def create_buttons
      # @type [Array<MoveButton>]
      @buttons = 4.times.map do |i|
        add_sprite(*BUTTON_COORDINATE[i], NO_INITIAL_IMAGE, i, type: MoveButton)
      end
    end

    def create_info
      # @type [MoveInfo]
      @info = add_sprite(0, 0, NO_INITIAL_IMAGE, self, type: MoveInfo)
    end

    def create_special_buttons
      @descr_button = add_sprite(12, 214, NO_INITIAL_IMAGE, :descr, type: SpecialButton)
      @mega_button = add_sprite(2, 188, NO_INITIAL_IMAGE, :mega, type: SpecialButton)
    end

    def create_cursor
      @cursor = add_sprite(0, 0, 'battle/arrow')
    end

    def create_move_description
      # Not added in the stack so it can be independant
      @move_description = MoveDescription.new(@viewport)
    end

    # Update the cursor position
    # @param silent [Boolean] if the update shouldn't make noise
    def update_cursor(silent = false)
      @cursor.set_position(@buttons[@index].x + CURSOR_OFFSET_X, @buttons[@index].y + CURSOR_OFFSET_Y)
      $game_system.se_play($data_system.cursor_se) unless silent
    end

    # Validate the user choice
    def validate
      @result = @pokemon.moveset[@index]
      @last_indexes[@pokemon] = @index
      $game_system.se_play($data_system.decision_se)
    end

    # Tell if the player is validating his choice
    def validating?
      return Input.trigger?(:A) || (Mouse.trigger?(:LEFT) && @buttons.any?(:simple_mouse_in?))
    end

    # Tell if the player is trying to use one of the special button
    # @return [Boolean]
    def special_validating?
      return true if Input.trigger?(:X) || Input.trigger?(:Y)

      return Mouse.trigger?(:LEFT) && (@descr_button.simple_mouse_in? || @mega_button.simple_mouse_in?)
    end

    # Do the special validation (saved actions)
    def special_validate
      if Input.trigger?(:Y) || (Mouse.trigger?(:LEFT) && @descr_button.simple_mouse_in?) || @move_description.visible
        @move_description.visible = !@move_description.visible
        # TODO: add go-ing go-out
      else
        # TODO : Add Mega action
      end
    end

    # Cancel the player choice
    def cancel
      @result = :cancel
      $game_system.se_play($data_system.cancel_se)
    end

    # Tell if the player is canceling his choice
    def canceling?
      return Input.trigger?(:B) || Mouse.trigger?(:RIGHT)
    end

    # Update the mouse index if the mouse moved
    def update_mouse_index
      return unless Mouse.moved

      @buttons.each do |sp|
        break @index = sp.index if sp.simple_mouse_in?
      end
    end

    # Update the index if a key was pressed
    def update_key_index
      if Input.repeat?(:UP)
        @index = (@index - 1) % @buttons.count(&:visible)
      elsif Input.repeat?(:DOWN)
        @index = (@index + 1) % @buttons.count(&:visible)
      end
    end

    # Button of a move
    class MoveButton < UI::SpriteStack
      # Get the index
      # @return [Integer]
      attr_reader :index

      # Create a new Move button
      # @param viewport [Viewport]
      # @param index [Integer]
      def initialize(viewport, index)
        super(viewport)
        @index = index
        create_sprites
      end

      # Set the data
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        move = pokemon.moveset[@index]
        if (self.visible = move)
          @background.sy = move.type
          @text.data = move
        end
      end

      private

      def create_sprites
        # TODO: separate in methods
        @background = add_sprite(0, 0, 'battle/types', 1, GameData::Type.all.size, type: SpriteSheet)
        @text = add_text(28, 8, 0, 16, :name, color: 10, type: UI::SymText)
      end
    end

    # Element showing the information of the current move
    class MoveInfo < UI::SpriteStack
      # Create a new MoveInfo
      # @param viewport [Viewport]
      # @param move_choice [SkillChoice]
      def initialize(viewport, move_choice)
        super(viewport)
        @move_choice = move_choice
        create_sprites
      end

      # Set the move shown by the UI
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        super(pokemon.moveset[@move_choice.index])
      end

      private

      def create_sprites
        @pp_background = add_sprite(122, 214, 'battle/pp_box', 1, 3, type: SpriteSheet)
        @pp_text = add_text(132, 220, 0, 16, :pp_text, 1, color: 10, type: UI::SymText)
        @move_category = add_sprite(122, 198, NO_INITIAL_IMAGE, type: UI::CategorySprite)
      end
    end

    # Element showing the full description about the currently selected move
    class MoveDescription < UI::SpriteStack
      # Create a new MoveDescription
      # @param viewport [Viewport]
      def initialize(viewport)
        super(viewport)
        create_sprites
        self.visible = false
      end

      private

      def create_sprites
        @background = add_background('battle/background')
        @box = add_sprite(0, 71, 'battle/description_box')
        @skill_name = add_text(14, 15, 0, 16, :name, type: UI::SymText)
        @power_text = add_text(133, 15, 0, 16, text_get(27, 37), color: 10)
        @power_value = add_text(193, 15, 0, 16, :power_text, 2, type: UI::SymText)
        @accuracy_text = add_text(229, 15, 0, 16, text_get(27, 39), color: 10)
        @accuracy_value = add_text(289, 15, 0, 16, :accuracy_text, 2, type: UI::SymText)
        @description = add_text(14, 36, 284, 16, :description, color: 0, type: UI::SymMultilineText)
      end
    end

    # Element showing a special button
    class SpecialButton < UI::SpriteStack
      # Create a new special button
      # @param viewport [Viewport]
      # @param type [Symbol] :mega or :descr
      def initialize(viewport, type)
        super(viewport)
        @type = type
        create_sprites
      end

      # Set the data of the button
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        # TODO: Add mega tool check!!!
        self.visible = @type == :descr || pokemon.can_mega_evolve?
      end

      # Update the special button content
      def refresh
        @text.text = @type == :descr ? 'Description' : 'Mega evolution'
      end

      private

      def create_sprites
        # TODO: separate in methods
        add_background(@type == :descr ? 'battle/button_x' : 'battle/button_mega')
        @text = add_text(23, 6, 0, 16, nil.to_s, color: 10)
        add_sprite(5, 5, @type == :descr ? 'battle/icon_x_triggered' : 'battle/icon_y_triggered')
      end
    end
  end
end
