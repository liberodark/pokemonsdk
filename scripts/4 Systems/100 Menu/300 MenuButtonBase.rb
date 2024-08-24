module UI
  # Button that is shown in the main menu
  class PSDKMenuButtonBase < SpriteStack
    # Basic coordinate of the button on screen
    BASIC_COORDINATE = [192, 16]
    # Offset between each button
    OFFSET_COORDINATE = [0, 24]
    # Offset between selected position and unselected position
    SELECT_POSITION_OFFSET = [-6, 0]
    # Angle variation of the icon in one direction
    ANGLE_VARIATION = 15

    # @return [Boolean] selected
    attr_reader :selected

    # Create a new PSDKMenuButton
    # @param viewport [Viewport]
    # @param real_index [Integer] real index of the button in the menu
    # @param positional_index [Integer] index used to position the button on screen
    def initialize(viewport, real_index, positional_index)
      super(viewport, *coordinates(positional_index))
      @index = real_index
      @selected = false
      create_sprites
    end

    # Update the button animation
    def update
      @animation.update if @animation
    end

    # Set the selected state
    # @param value [Boolean]
    def selected=(value)
      return if value == @selected

      if value
        move(*SELECT_POSITION_OFFSET)
        @icon.select(1, icon_index)
        @animation = create_animation
      else
        move(-SELECT_POSITION_OFFSET.first, -SELECT_POSITION_OFFSET.last)
        @icon.select(0, icon_index)
        @icon.angle = 0
        @animation = nil
      end
      @selected = value
    end

    private

    # Compute the button x, y coordinate on the screen based on index
    # @param index [Integer]
    # @return [Array<Integer>]
    def coordinates(index)
      x = BASIC_COORDINATE.first + index * OFFSET_COORDINATE.first
      y = BASIC_COORDINATE.last + index * OFFSET_COORDINATE.last
      return x, y
    end

    def create_sprites
      create_background
      create_icon
      create_text
    end

    def create_background
      add_background('menu_button')
    end

    def create_icon
      # @type [SpriteSheet]
      @icon = add_sprite(12, 0, 'menu_icons', 2, 8, type: SpriteSheet)
      @icon.select(0, icon_index)
      @icon.set_origin(@icon.width / 2, @icon.height / 2)
      @icon.set_position(@icon.x + @icon.ox, @icon.y + @icon.oy)
    end

    # Get the icon index
    # @return [Integer]
    def icon_index
      @index
    end

    def create_text
      add_text(40, 0, 0, 23, text.sub(PFM::Text::TRNAME[0], $trainer.name))
    end

    # Get the text based on the index
    # @return [Integer]
    def text
      case @index
      when 0 then return text_get(14, 1) # Dex
      when 1 then return text_get(14, 0) # PARTY
      when 2 then return text_get(14, 2) # BAG
      when 3 then return text_get(14, 3) # TCARD
      when 4 then return text_get(14, 5) # Options
      when 5 then return text_get(14, 4) # Save
      else
        return ext_text(9000, 26) # Quit
      end
    end

    def create_animation
      ya = Yuki::Animation
      animation = ya.timed_loop_animation(1)
      animation.play_before(ya.wait(1))
      angle_animation = ya.scalar(0.5, @icon, :angle=, ANGLE_VARIATION, -ANGLE_VARIATION)
      angle_animation.play_before(ya.scalar(0.5, @icon, :angle=, -ANGLE_VARIATION, ANGLE_VARIATION))
      animation.parallel_add(angle_animation)
      animation.start
      return animation
    end
  end
end
