module Audio
  class SFMLAudioDriver < DriverBase
    # Create a new SFML Audio Driver
    def initialize
      @channels = {
        bgm: SFMLAudio::Music.new,
        bgs: SFMLAudio::Music.new,
        me: SFMLAudio::Sound.new,
      }
      @fade_settings = {}
      @mute_settings = {}
      @me_buffer = SFMLAudio::SoundBuffer.new
      @se_sounds = {}
      @se_buffers = {}
      @cries_stack = []
    end

    # Reset the driver
    def reset
      @channels.each_key { |s| stop_channel(s) }
      @se_sounds.each_value(&:stop)
      @cries_stack.each(&:stop)
      @cries_stack.clear
      @se_sounds.clear
    end

    # Release the driver
    def release
      reset
    end

    # Update the driver
    def update
      @fade_settings.each { |k, v| update_fade(k, *v) }
      @mute_settings.each { |k, v| update_mute(k, v) }
    end

    # Play a sound (just once)
    # @param channel [Symbol] channel for the sound (:se, :me)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    def play_sound(channel, filename, volume, pitch)
      stop_channel(channel)
      return unless (memory = try_load(filename))

      c = channel == :se ? get_se_sound(filename) : (@channels[channel] ||= SFMLAudio::Sound.new)
      buffer = channel == :me ? @me_buffer : (@se_buffers[filename] ||= SFMLAudio::SoundBuffer.new)
      buffer.load_from_memory(memory)
      c.set_buffer(buffer)
      c.set_pitch(pitch / 100.0)
      c.set_volume(volume / 100.0)
      c.play
    end

    # Play a music (looped)
    # @param channel [Symbol] channel for the music (:bgm, :bgs)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    # @param fade_with_previous [Boolean] if the previous music should be faded with this one
    def play_music(channel, filename, volume, pitch, fade_with_previous)
      stop_channel(channel)
      return unless (memory = try_load(filename))

      c = (@channels[channel] ||= SFMLAudio::Music.new)
      c.open_from_memory(memory)
      auto_loop(c, memory)
      c.set_loop(true)
      c.set_pitch(pitch / 100.0)
      c.set_volume(volume / 100.0)
      c.play
      c.pause if @mute_settings[channel]
    end

    # Fade a channel out
    # @param channel [Symbol] channel to fade
    # @param duration [Integer] duration of the fade out in ms
    def fade_channel_out(channel, duration)
      c = @channels[channel]
      return if !c || c.stopped?

      @fade_settings[channel] = [Time.new, c.get_volume, duration / 1000.0]
    end

    # Stop a channel
    # @param channel [Symbol] channel to stop
    def stop_channel(channel)
      if channel == :se
        @se_sounds.each_value(&:stop)
        @cries_stack.each(&:stop)
        @cries_stack.clear
        @se_sounds.clear
        @se_buffers.clear
        return
      end
      @fade_settings.delete(channel)
      c = @channels[channel]
      return if !c || c.stopped?

      c.stop
    end

    # Set a channel volume
    # @param channel [Symbol] channel to set the volume
    # @param volume [Integer] volume of the channel (0~100)
    def set_channel_volume(channel, volume)
      c = @channels[channel]
      return if !c || c.stopped?

      c.set_volume(volume / 100.0)
    end

    # Get a channel audio position
    # @param channel [Symbol]
    # @return [Integer] channel audio position in driver's unit
    def get_channel_audio_position(channel)
      c = @channels[channel]
      return 0 if !c || c.stopped?

      return (c.get_playing_offset * c.get_sample_rate).to_i
    end

    # Set a channel audio position
    # @param channel [Symbol]
    # @param position [Integer] audio position in driver's unit
    def set_channel_audio_position(channel, position)
      c = @channels[channel]
      return if !c || c.stopped?

      c.set_playing_offset(position / c.get_sample_rate.to_f)
    rescue StandardError
      log_error("set_channel_audio_position= : #{$!.message}")
    end

    # Mute a channel for an amount of time
    # @param channel [Symbol]
    # @param duration [Integer] mute duration in driver's time
    def mute_channel_for(channel, duration)
      c = @channels[channel]
      return if !c || c.stopped?

      @mute_settings[channel] = Graphics.current_time + duration
      c.pause
    end

    # Unmute a channel
    # @param channel [Symbol]
    def unmute_channel(channel)
      c = @mute_settings.delete(channel)
      return if !c || c.stopped?

      c.play
    end

    # Get a channel duration
    # @param channel [Symbol]
    # @return [Integer]
    def get_channel_duration(channel)
      c = @channels[channel]
      return 0 if !c || c.stopped?

      return channel == :me ? @me_buffer.get_duration : c.get_duration
    end

    private

    # Automatically loop an audio
    # @param music [SFMLAudio::Music]
    # @param memory [String] audio file content
    def auto_loop(music, memory)
      data = memory[0, 2048]
      start_index = data.index('LOOPSTART=')
      length_index = data.index('LOOPLENGTH=')
      return unless start_index && length_index

      start = data[start_index + 10, 20].to_i
      lenght = data[length_index + 11, 20].to_i
      log_info("LOOP: #{start} -> #{start + lenght}") unless PSDK_CONFIG.release?
      frequency = music.get_sample_rate.to_f
      music.set_loop_points(start / frequency, lenght / frequency)
    end

    # Update a fading operation
    # @param channel [Symbol]
    # @param start_time [Time]
    # @param volume [Float]
    # @param duration [Float]
    # @return [Boolean] if the sound should be stopped
    def update_fade(channel, start_time, volume, duration)
      c = @channels[channel]
      current_duration = Graphics.current_time - start_time
      if c && !c.stopped? && current_duration < duration
        sound.set_volume(volume * (1 - current_duration / duration))
      else
        @fade_settings.delete(channel)
        stop_channel(channel)
      end
    end

    # Update a mute operation
    # @param channel [Symbol]
    # @param end_mute [Time]
    def update_mute(channel, end_mute)
      c = @channels[channel]
      if end_mute >= Graphics.current_time
        @mute_settings.delete(channel)
        c.play if c && c.stopped?
      end
    end

    # Get the SE sound
    # @param filename [String]
    # @return [SFMLAudio::Sound]
    def get_se_sound(filename)
      sound = SFMLAudio::Sound.new
      if file_name.downcase.include?('/cries/')
        @cries_stack << sound
        @cries_stack.shift.stop if @cries_stack.size > 5
      else
        @se_sounds[file_name] = sound
      end
      return sound
    end
  end

  register_driver(:sfml, SFMLAudioDriver) if Object.const_defined?(:SFMLAudio)
end
