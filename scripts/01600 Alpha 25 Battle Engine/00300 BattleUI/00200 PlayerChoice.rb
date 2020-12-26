module BattleUI
  # Class that allow the player to make the choice of the action he want to do
  #
  # The object tells the player validated on #validated? and the result is stored inside #result
  #
  # The object should be updated through #update otherwise no validation is possible
  #
  # When result was taken, the scene should call #reset to undo the validated state
  class PlayerChoice < UI::SpriteStack
    include UI
    # Offset X of the cursor compared to the element it shows
    CURSOR_OFFSET_X = -10
    # Offset Y of the cursor compared to the element it shows
    CURSOR_OFFSET_Y = 6
    # Coordinate of each buttons
    BUTTON_COORDINATE = [[172, 172], [246, 182], [162, 201], [236, 211]]
    # List of the possible result on validation (according to the index)
    POSSIBLE_RESULT = %i[attack bag pokemon flee]
    # The result
    # @return [Symbol, nil]
    attr_reader :result
    # The possible action made by the player (other than choosing a sub action)
    # @return [Battle::Actions::Base]
    attr_reader :action
    # Tell if the player can switch or not
    # @return [Boolean]
    attr_accessor :can_switch
    # Create a new PlayerChoice Window
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    def initialize(viewport, scene)
      super(viewport)
      @scene = scene
      @index = 0
      @can_switch = true
      create_sprites
      self.visible = false
    end

    # Update the Window cursor
    def update
      return if validated?
      return special_validate if special_validating?
      return if @item_info.visible
      return validate if validating?
      return cancel if canceling?

      last_index = @index
      update_key_index
      update_mouse_index
      update_cursor if last_index != @index
    end

    # If the player made a choice
    # @return [Boolean]
    def validated?
      !@result.nil?
    end

    # Reset the choice
    def reset
      @result = nil
      @action = nil
      @last_item_button.refresh
      @scene.visual.hide_info_bars(bank: 0)
      update_cursor(true)
    end

    private

    def create_sprites
      create_buttons
      create_special_buttons
      create_cursor
      create_item_info
    end

    def create_buttons
      # @type [Array<Button>]
      @buttons = 4.times.map do |i|
        add_sprite(*BUTTON_COORDINATE[i], NO_INITIAL_IMAGE, i, type: Button)
      end
    end

    def create_special_buttons
      @last_item_button = add_sprite(12, 214, NO_INITIAL_IMAGE, :last_item, type: SpecialButton)
      @info_button = add_sprite(2, 188, NO_INITIAL_IMAGE, :info, type: SpecialButton)
    end

    def create_cursor
      @cursor = add_sprite(0, 0, 'battle/arrow')
    end

    def create_item_info
      @item_info = ItemInfo.new(@viewport)
      @item_info.visible = false
    end

    # Update the cursor position
    # @param silent [Boolean] if the update shouldn't make noise
    def update_cursor(silent = false)
      @cursor.set_position(@buttons[@index].x + CURSOR_OFFSET_X, @buttons[@index].y + CURSOR_OFFSET_Y)
      $game_system.se_play($data_system.cursor_se) unless silent
    end

    # Validate the player choice
    def validate
      @result = POSSIBLE_RESULT[@index]
      if @result == :pokemon && !@can_switch
        $game_system.se_play($data_system.buzzer_se)
        return reset
      else
        $game_system.se_play($data_system.decision_se)
      end
    end

    # Tell if the player is validating his choice
    def validating?
      return Input.trigger?(:A) || (Mouse.trigger?(:LEFT) && @buttons.any?(:simple_mouse_in?))
    end

    # Tell if the player is trying to use one of the special button
    # @return [Boolean]
    def special_validating?
      return true if Input.trigger?(:X) || Input.trigger?(:Y)

      return Mouse.trigger?(:LEFT) && (@info_button.simple_mouse_in? || @last_item_button.simple_mouse_in?)
    end

    # Do the special validation (saved actions)
    def special_validate
      if Input.trigger?(:Y) || (Mouse.trigger?(:LEFT) && @info_button.simple_mouse_in?)
        # TODO : Show Info
      else
        id = $bag.last_battle_item.id
        return $game_system.se_play($data_system.buzzer_se) unless $bag.contain_item?(id)

        if @item_info.visible
          # TODO: cancelation
          user = @scene.logic.battler(0, @scene.player_actions.size)
          @action = Battle::Actions::Item.new(@scene, PFM::ItemDescriptor.actions(id), $bag, user)
          @result = :other
          @item_info.visible = false
        else
          @item_info.visible = true
        end
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
      if Input.trigger?(:UP)
        @index = (@index - 2).clamp(0, POSSIBLE_RESULT.size - 1)
      elsif Input.trigger?(:LEFT)
        @index = (@index - 1).clamp(0, POSSIBLE_RESULT.size - 1)
      elsif Input.trigger?(:RIGHT)
        @index = (@index + 1).clamp(0, POSSIBLE_RESULT.size - 1)
      elsif Input.trigger?(:DOWN)
        @index = (@index + 2).clamp(0, POSSIBLE_RESULT.size - 1)
      end
    end

    # Button of the player choice
    class Button < SpriteSheet
      # Create a new Player Choice button
      # @param viewport [Viewport]
      # @param index [Integer]
      def initialize(viewport, index)
        super(viewport, 4, 1)
        self.index = index
        set_bitmap(image_filename, :interface)
      end

      alias index sx
      alias index= sx=

      # Get the filename of the sprite
      # @return [String]
      def image_filename
        return 'battle/actions_'
      end
    end

    # Element showing a special button
    class SpecialButton < UI::SpriteStack
      # Create a new special button
      # @param viewport [Viewport]
      # @param type [Symbol] :last_item or :info
      def initialize(viewport, type)
        super(viewport)
        @type = type
        create_sprites
      end

      # Update the special button content
      def refresh
        @text.text = @type == :info ? 'Information' : $bag.last_battle_item.name
      end

      private

      def create_sprites
        # TODO: separate in methods
        add_background(@type == :info ? 'battle/button_y' : 'battle/button_x')
        @text = add_text(23, 6, 0, 16, nil.to_s, color: 10)
        add_sprite(5, 5, @type == :info ? 'battle/icon_y_triggered' : 'battle/icon_x_triggered')
      end
    end

    # UI showing the info about the last used item
    class ItemInfo < UI::SpriteStack
      # Create a new Item Info box
      # @param viewport [Viewport]
      def initialize(viewport)
        super(viewport)
        create_sprites
      end

      # Set the data shown by the UI
      # @param item [GameData::Item]
      def data=(item)
        super
        @remaining.text = $bag.item_quantity(item.id).to_s
      end

      private

      def create_sprites
        @background = add_background('battle/background')
        @item_box = add_sprite(0, 61, 'battle/last_item_box')
        @item_name = add_text(14, 15, 0, 16, :exact_name, color: 0, type: UI::SymText)
        @item_icon = add_sprite(240, 2, NO_INITIAL_IMAGE, type: UI::ItemSprite)
        @remaining = add_text(289, 15, 0, 16, nil.to_s, 2)
        @description = add_text(14, 36, 284, 16, :descr, color: 0, type: UI::SymMultilineText)
        @use_text = add_text(151, 90, 0, 16, text_get(22, 0), color: 10)
        @icon = add_sprite(131, 90, 'battle/icon_x_triggered')
      end
    end
  end
end
