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
  # @return [Hash, nil] hash if a charset animation is setup, else nil
  attr_accessor :charset_animation
  # @return [Integer, nil] offset y of the character on the screen
  attr_accessor :offset_screen_y
  # @return [Integer, nil] offset y of the character on the screen
  attr_accessor :offset_shadow_screen_y
  # @return [Integer, nil] offset x of the character on the screen
  attr_accessor :offset_screen_x
  # @return [Integer, nil] offset x of the character on the screen
  attr_accessor :offset_shadow_screen_x

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

  # Set the charset animation. It can be needed to set the event in direction fixed.
  # @param lines [Array<Integer>] list of the lines to animates (0,1,2,3)
  # @param duration [Integer] duration of the animation in frame (30 frames per secondes)
  # @param reverse [Boolean] <default: false> set it to true if the animation is reversed
  # @param repeat [Boolean, Integer] true if looping continuously, Integer for the number of loops, false for no loops
  # @param last_frame_delay [Boolean] if the delay should also be applied to the last frame of the animation
  # @param reset_at_end [Boolean] if the character's appearance should be set back to the first frame at the end of the anim
  # @return [Boolean]
  def animate_from_charset(lines, duration, reverse: false, repeat: false, last_frame_delay: false, reset_at_end: false)
    # Calculate and store the frames to display
    frames = []
    lines.each do |dir|
      [0, 1, 2, 3].each do |pattern|
        frames.push((((dir + 1) * 2) << 2) | pattern)	# A frame is 0bdddpp with ddd the direction, pp the pattern
      end
    end
    frames.reverse! if reverse  # Invert the animation if asked
    # Contain the charset animation data
    @charset_animation = {
      running: true,                                     # Indicate if the animation need to be updated or not
      frames: frames,                                    # List of frames
      delay: (duration.to_f / frames.size.to_f).round,   # Delay between two frame in frames
      repeat: repeat,                                    # Indicate if the animation is looped or not
      last_frame_delay: last_frame_delay,                # Indicate if the last_frame should also have the delay applied
      reset_at_end: reset_at_end,                        # Indicate if the appearance should be set to the first frame at the end
      counter: -1,                                       # Frame counter (initialized at -1 so the first update will set the appearance)
      index: 0                                           # Index of the current frame to display
    }
    return update_charset_animation # First update, display the first frame
  end

  # Cancel the charset animation
  def cancel_charset_animation
    @charset_animation = nil
  end

  # Tell the Game_Character to wait for its charset animation to finish
  def wait_charset_animation
    @wait_charset_animation = true
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

  # Update the charset animation and return true if there is a charset animation
  # @return [Boolean]
  def update_charset_animation
    anim = @charset_animation
    # Check update need
    return false unless anim&.dig(:running)
    # Check delay
    return true unless ((anim[:counter] += 1) % anim[:delay]) == 0

    update_charset_anim_appearance(anim[:index]) if anim[:frames][anim[:index]]
    # Update the index and the repeat
    if (anim[:index] += 1) >= anim[:frames].length
      return true if last_frame_delay? && (anim[:repeat].is_a?(Integer) ? (anim[:repeat] - 1) == 0 : anim[:repeat])

      if should_charset_anim_loop?
        anim[:index] = 0
      else
        if anim[:reset_at_end]
          update_charset_anim_appearance(0)
        else
          @original_pattern = @pattern
        end
        anim[:running] = false
        @wait_charset_animation = false
      end
    end
    return true
  end

  # Tell if the @charset_animation should loop
  # @return [Boolean]
  def should_charset_anim_loop?
    return true if @charset_animation[:repeat] == true

    if @charset_animation[:repeat].is_a?(Integer) && @charset_animation[:repeat] > 0
      return true if (@charset_animation[:repeat] -= 1) > 0
    end
    return false
  end

  # Tells if a delay should be applied on the last frame of the charset_animation
  # @return [Boolean]
  def last_frame_delay?
    anim = @charset_animation
    return true if anim[:last_frame_delay] && anim[:index] == anim[:frames].length

    return false
  end

  # Update the appearance with the given index in the charset_animation
  # @param index [Integer] the index of the frame we want to update to
  def update_charset_anim_appearance(index)
    # Update the appearance
    frame = @charset_animation[:frames][index]
    @direction = (frame >> 2)
    @pattern = (frame & 0b11)
  end
end
