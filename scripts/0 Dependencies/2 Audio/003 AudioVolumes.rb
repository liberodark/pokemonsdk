module Audio
  @music_volume = 100
  @sfx_volume = 100

  module_function

  # Get volume of bgm and me
  # @return [Integer] a value between 0 and 100
  def music_volume
    return @music_volume
  end

  # Set the volume of bgm and me
  # @param value [Integer] a value between 0 and 100
  def music_volume=(value)
    volume = value.to_i.clamp(0, 100)
    @music_volume = volume
    music_channels.each do |channel|
      @driver.set_channel_volume(channel, volume)
    end
  end

  # Get all the music channels (to patch if you want to include more)
  # @return [Array<Symbol>]
  def music_channels
    %i[bgm me]
  end

  # Get volume of sfx
  # @return [Integer] a value between 0 and 100
  def sfx_volume
    return @sfx_volume
  end

  # Set the volume of sfx
  # @param value [Integer] a value between 0 and 100
  def sfx_volume=(value)
    volume = value.to_i.clamp(0, 100)
    @sfx_volume = volume
    sfx_channels.each do |channel|
      @driver.set_channel_volume(channel, volume)
    end
  end

  # Get all the sfx channels (to patch if you want to include more)
  # @return [Array<Symbol>]
  def sfx_channels
    %i[bgs]
  end
end
