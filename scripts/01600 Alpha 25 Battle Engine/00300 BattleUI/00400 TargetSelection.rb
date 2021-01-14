module BattleUI
  class TargetSelection < UI::SpriteStack
    # @return [Array, :cancel] the position (bank, position) of the choosen target
    attr_accessor :result
    # Create a new TargetSelection
    # @param viewport [LiteRGSS::Viewport]
    # @param launcher [PFM::PokemonBattler]
    # @param move [Battle::Move]
    # @param logic [Battle::Logic]
    def initialize(viewport, launcher, move, logic)
      super(viewport)
      @launcher = launcher
      @move = move
      @logic = logic
      @row_size = logic.battle_info.vs_type
      @targets = move.battler_targets(launcher, logic).select(&:alive?)
      @allow_selection = !move.no_choice_skill?
      @mons = generate_mon_list
      @index = find_best_index
      create_sprites
      update_cursor(true) if @allow_selection
    end

    # Update the Window cursor
    def update
      super
      return if validated?
      return validate if Input.trigger?(:A)
      return cancel if Input.trigger?(:B)
      return unless @allow_selection

      last_index = @index
      update_key_index
      update_mouse_index
      update_cursor if last_index != @index && @allow_selection
    end

    # If the player made a choice
    # @return [Boolean]
    def validated?
      !@result.nil?
    end

    private

    def update_key_index
      if Input.repeat?(:UP)
        @index = (@index - @row_size) % @buttons.size
      elsif Input.repeat?(:RIGHT)
        @index = (@index + 1) % @buttons.size
      elsif Input.repeat?(:LEFT)
        @index = (@index - 1) % @buttons.size
      elsif Input.repeat?(:DOWN)
        @index = (@index + @row_size) % @buttons.size
      end
    end

    def update_mouse_index
      return unless Mouse.moved

      @buttons.each_with_index do |button, index|
        break @index = index if button.simple_mouse_in?
      end
    end

    def create_sprites
      add_background('battle/background')
      @buttons = @mons.map.with_index do |pokemon, index|
        push_sprite(Button.new(@viewport, index, @row_size, pokemon, @launcher, @move, @targets.include?(pokemon)))
      end
    end

    # Validate the player choice
    def validate
      return @result = [1, 0] if @targets.empty?

      target = @allow_selection ? @buttons[@index].data : @targets.first
      if @targets.include?(target)
        @result = [target.bank, target.position]
        $game_system.se_play($data_system.decision_se)
      else
        $game_system.se_play($data_system.buzzer_se)
      end
    end

    # Cancel the player choice
    def cancel
      @result = :cancel
      $game_system.se_play($data_system.cancel_se)
    end

    # Update the cursor position
    # @param silent [Boolean] if the cursor se should not be played
    def update_cursor(silent = false)
      @buttons.each_with_index { |button, index| button.selected = @index == index }
      $game_system.se_play($data_system.cursor_se) unless silent
    end

    # Generate the list of mons shown by the UI
    # @return [Array<PFM::PokemonBattler>]
    def generate_mon_list
      2.times.map do |bank|
        @logic.battle_info.vs_type.times.map do |position|
          @logic.battler(bank, position)
        end
      end.reverse.flatten
    end

    # Find the best possible index as default index
    # @return [Integer]
    def find_best_index
      return @mons.index(@targets.first).to_i
    end

    # Button shown by the UI to get what's selected
    class Button < UI::SpriteStack
      # Get the selected state of the button
      # @return [Boolean]
      attr_reader :selected
      # Create a new button
      # @param viewport [Viewport]
      # @param index [Integer]
      # @param row_size [Integer]
      # @param pokemon [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @parma is_target [Boolean]
      def initialize(viewport, index, row_size, pokemon, launcher, move, is_target)
        super(viewport, *process_coordinates(index, row_size))
        create_sprites
        @move = move
        @selected = is_target
        @is_target = is_target
        @launcher = launcher
        self.data = pokemon
      end

      # Set the selected state about the button
      # @param selected [Boolean]
      def selected=(selected)
        @selected = selected
        @cursor.set_position(@x - 10, @y + 12)
        @cursor.visible = selected
      end

      # Set the Pokemon shown
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        super(pokemon)
        self.visible = pokemon&.alive?
        unless visible
          @background.visible = true
          return
        end

        @gender.x = @name.x + @name.real_width + 5
        @icon.opacity = @is_target ? 255 : 128
        @efficiency_text.text = load_efficiency_text(pokemon)
        @efficiency_text.visible = @is_target
        self.selected = @selected
      end

      private

      def create_sprites
        @background = add_background(NO_INITIAL_IMAGE, type: Background)
        @icon = add_sprite(1, 1, NO_INITIAL_IMAGE, false, type: UI::PokemonIconSprite)
        @name = add_text(41, 16, 0, 16, :name, color: 10, type: UI::SymText)
        @gender = add_sprite(5, 16, NO_INITIAL_IMAGE, type: UI::GenderSprite)
        @efficiency_text = add_text(18, 35, 102, 16, nil.to_s, 1, color: 10)
        @cursor = add_sprite(-10, 12, 'battle/arrow', type: Cursor)
        @cursor.visible = false
      end

      # @param pokemon [PFM::PokemonBattler]
      # @return [String]
      def load_efficiency_text(pokemon)
        efficiency = @move.type_modifier(@launcher, pokemon)
        return ext_text(8999, 23) if efficiency >= 2
        return ext_text(8999, 24) if efficiency == 0
        return ext_text(8999, 25) if efficiency < 1

        return ext_text(8999, 22)
      end

      def process_coordinates(index, row_size)
        x = index % row_size
        y = index / row_size
        return (29 - 10 * y + 141 * x), 65 + y * 58
      end

      class Background < Sprite
        # Set the Pokemon shown
        # @param pokemon [PFM::PokemonBattler]
        def data=(pokemon)
          return unless pokemon
          set_bitmap(image_name(pokemon), :interface)
        end

        private

        # Get the image that should be shown by the UI
        # @param pokemon [PFM::PokemonBattler]
        def image_name(pokemon)
          return 'battle/target_bar_enemy' if pokemon.bank != 0
          return 'battle/target_bar_ally' unless pokemon.from_party?

          return 'battle/target_bar_player'
        end
      end
    end
  end
end
