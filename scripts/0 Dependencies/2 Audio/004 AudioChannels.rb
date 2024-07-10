module Audio
  # Constant allowing maker to define if music must fade in by default
  FADE_IN_BY_DEFAULT = true

  module_function

  # plays a BGM and stop the current one
  # @param filename [String] name of the audio file
  # @param volume [Integer] volume of the BGM between 0 and 100
  # @param pitch [Integer] speed of the BGM in percent
  # @param fade_in [Boolean, Integer] if the BGM fades in when different (or time in ms)
  def bgm_play(filename, volume = 100, pitch = 100, fade_in = FADE_IN_BY_DEFAULT)
    @driver&.play_music(:bgm, filename, volume * @music_volume / 100, pitch, fade_in)
  end

  # Returns the BGM position
  # @return [Integer]
  def bgm_position
    @driver&.get_channel_audio_position(:bgm) || 0
  end

  # Set the BGM position
  # @param position [Integer]
  def bgm_position=(position)
    @driver&.set_channel_audio_position(:bgm, position)
  end

  # Fades the BGM
  # @param time [Integer] fade time in ms
  def bgm_fade(time)
    @driver&.fade_channel_out(:bgm, time)
  end

  # Stop the BGM
  def bgm_stop
    @driver&.stop_channel(:bgm)
  end

  # plays a BGS and stop the current one
  # @param filename [String] name of the audio file
  # @param volume [Integer] volume of the BGS between 0 and 100
  # @param pitch [Integer] speed of the BGS in percent
  # @param fade_in [Boolean, Integer] if the BGS fades in when different (or time in ms)
  def bgs_play(filename, volume = 100, pitch = 100, fade_in = FADE_IN_BY_DEFAULT)
    @driver&.play_music(:bgs, filename, volume * @sfx_volume / 100, pitch, fade_in)
  end

  # Returns the BGS position
  # @return [Integer]
  def bgs_position
    @driver&.get_channel_audio_position(:bgs) || 0
  end

  # Set the BGS position
  # @param position [Integer]
  def bgs_position=(position)
    @driver&.set_channel_audio_position(:bgs, position)
  end

  # Fades the BGS
  # @param time [Integer] fade time in ms
  def bgs_fade(time)
    @driver&.fade_channel_out(:bgs, time)
  end

  # Stop the BGS
  def bgs_stop
    @driver&.stop_channel(:bgs)
  end

  # plays a ME and stop the current one
  # @param filename [String] name of the audio file
  # @param volume [Integer] volume of the ME between 0 and 100
  # @param pitch [Integer] speed of the ME in percent
  # @param preserve_bgm [Boolean] if the bgm should not be paused
  def me_play(filename, volume = 100, pitch = 100, preserve_bgm = false)
    @driver&.play_sound(:me, filename, volume * @music_volume / 100, pitch)
    return if preserve_bgm

    duration = @driver&.get_channel_duration(:me)
    @driver&.mute_channel_for(:bgm, duration * 100 / pitch) if duration && duration != 0
  end

  # Returns the ME position
  # @return [Integer]
  def me_position
    @driver&.get_channel_audio_position(:me) || 0
  end

  # Set the ME position
  # @param position [Integer]
  def me_position=(position)
    @driver&.set_channel_audio_position(:me, position)
  end

  # Fades the ME
  # @param time [Integer] fade time in ms
  def me_fade(time)
    @driver&.fade_channel_out(:me, time)
    @driver&.unmute_channel(:bgm)
  end

  # Stop the ME
  def me_stop
    @driver&.stop_channel(:me)
    @driver&.unmute_channel(:bgm)
  end

  # plays a SE if possible
  # @param filename [String] name of the audio file
  # @param volume [Integer] volume of the SE between 0 and 100
  # @param pitch [Integer] speed of the SE in percent
  def se_play(filename, volume = 100, pitch = 100)
    @driver&.play_sound(:se, filename, volume * @sfx_volume / 100, pitch)
  end

  # Stop SE
  def se_stop
    @driver&.stop_channel(:se)
    @driver&.stop_channel(:cries)
  end

  # plays a cry
  # @param filename [String] name of the audio file
  # @param volume [Integer] volume of the SE between 0 and 100
  # @param pitch [Integer] speed of the SE in percent
  def cry_play(filename, volume = 100, pitch = 100)
    @driver&.play_sound(:cries, filename, volume * @sfx_volume / 100, pitch)
  end
end
