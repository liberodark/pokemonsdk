class Game_Character
  # @return [Integer] ID of the tile shown as the event (0 = no tile)
  attr_reader :tile_id
  # @return [String] name of the character graphic used to display the event
  attr_accessor :character_name
  # @return [Intger] must be 0
  attr_accessor :character_hue
  # @return [Integer] opacity of the event when it's shown
  attr_accessor :opacity
  # @return [Integer] blending of the event (0 is the only one that actually works)
  attr_reader :blend_type
  # @return [Integer] current pattern of the character graphic shown
  attr_reader :pattern
  # @return [Boolean] if the event is invisible
  attr_accessor :transparent
  # @return [Boolean] if the event has a patern animation while staying
  attr_accessor :step_anime
  # @return [Boolean] if the shadow should be shown or not
  attr_accessor :shadow_disabled
  # @return [Integer, nil] offset y of the character on the screen
  attr_accessor :offset_screen_y
  # @return [Integer, nil] offset y of the character on the screen
  attr_accessor :offset_shadow_screen_y

  # Values that allows the shadow_disabled update in set_appearance
  SHADOW_DISABLED_UPDATE_VALUES = [false, true, nil]

  # Define the new appearance of the character
  # @param character_name [String] name of the character graphic to display
  # @param character_hue [Integer] must be 0
  def set_appearance(character_name, character_hue = 0)
    @character_name = character_name
    @character_hue = character_hue
    @shadow_disabled = character_name.empty? if @event && SHADOW_DISABLED_UPDATE_VALUES.include?(@shadow_disabled)
    change_shadow_disabled_state(true) if @surfing && !is_a?(Game_Player)
  end

  # bush_depth of the sprite of the character
  # @return [Integer]
  def bush_depth
    # タイルの場合、または最前面に表示フラグが ON の場合
    if @tile_id > 0 or @always_on_top
      return 0
    end
    # return 12 if @in_swamp #> Ajout des marais
    if @jump_count == 0 and $game_map.bush?(@x, @y)
      return 12
    else
      return 0
    end
  end

  private

  SHADOW_DISABLED_KEEP_VALUES = {
    NilClass => nil, nil => NilClass,
    FalseClass => false, false => FalseClass,
    TrueClass => true, true => TrueClass
  }
  # Change the shadow state in order to keep the old value
  # @param value [Boolean] new value
  def change_shadow_disabled_state(value)
    if value
      # If it's already true, we don't care
      @shadow_disabled ||= SHADOW_DISABLED_KEEP_VALUES[@shadow_disabled]
      # If it's not a Class object, we din't changed the value of the shadow_disabled
    elsif @shadow_disabled.is_a?(Class)
      @shadow_disabled = SHADOW_DISABLED_KEEP_VALUES[@shadow_disabled]
    end
  end
end
