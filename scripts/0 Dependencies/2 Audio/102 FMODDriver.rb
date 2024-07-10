module Audio
  class FMODDriver < DriverBase
    # List of the Audio extension that are supported
    AUDIO_FILENAME_EXTENSIONS = ['.ogg', '.mp3', '.wav', '.mid', '.aac', '.wma', '.it', '.xm', '.mod', '.s3m', '.midi', '.flac']
    # List of Audio Priorities (if not found => 128)
    AUDIO_PRIORITIES = { bgm: 0, me: 1, bgs: 2, se: 250, cries: 249 }
    # Time of the audio fade in
    FADE_IN_TIME = 250
    # This variable is there because there's a bug in Ruby-Fmod preventing to normally release the whole system
    # TODO: remove once the bug has been fixed on Ruby-Fmod
    @@BUG_FMOD_INITIALIZED = false

    # Create a new FMOD driver
    def initialize
      @sounds = {}
      @names = {}
      @channels = {}
      @se_sounds = {}
      @cries_stack = []
      @fading_sounds = {}
      @mutexes = Hash.new { |h,k| h[k] = Mutex.new }
      FMOD::System.init(64, FMOD::INIT::NORMAL) unless @@BUG_FMOD_INITIALIZED
      @@BUG_FMOD_INITIALIZED = true
    end

    # Update the driver (must be called every meaningful frames)
    def update
      FMOD::System.update
    end

    # Reset the driver
    def reset
      @channels.keys.each { |s| stop_channel(s) }
      @se_sounds.each_value(&:release)
      @se_sounds.clear
      @cries_stack.each(&:release)
      @cries_stack.clear
      @fading_sounds.each_key(&:release)
      @fading_sounds.clear
    end

    # Release the driver
    def release
      reset
      # FMOD::System.release # Not done because of a bug
    end

    # Play a sound (just once)
    # @param channel [Symbol] channel for the sound (:se, :me)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    def play_sound(channel, filename, volume, pitch)
      synchronize(@mutexes[channel]) do
        channel == :me ? play_me_sound(filename, volume, pitch) : play_se_sound(filename, volume, pitch)
      end
    end

    # Play a music (looped)
    # @param channel [Symbol] channel for the music (:bgm, :bgs)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    # @param fade_with_previous [Boolean] if the previous music should be faded with this one
    def play_music(channel, filename, volume, pitch, fade_with_previous)
      Thread.new do
        synchronize(@mutexes[channel]) do
          play_music_internal(channel, filename, volume, pitch, fade_with_previous)
        end
      end
    end

    # Fade a channel out
    # @param channel [Symbol] channel to fade
    # @param duration [Integer] duration of the fade out in ms
    def fade_channel_out(channel, duration)
      synchronize(@mutexes[channel]) do
        c = @channels[channel]
        sound = @sounds[channel]
        return if !c || !sound || @fading_sounds[sound]

        fade(duration, @fading_sounds[sound] = c)
        @channels.delete(channel)
      rescue FMOD::Error
        @fading_sounds.delete(sound)
        @channels.delete(channel)
      end
    end

    # Stop a channel
    # @param channel [Symbol] channel to stop
    def stop_channel(channel)
      if channel == :se
        @se_sounds.each_value(&:release)
        @se_sounds.clear
        @cries_stack.each(&:release)
        @cries_stack.clear
        return
      end

      synchronize(@mutexes[channel]) do
        @channels[channel]&.stop
      rescue FMOD::Error => e
        puts "Failed to properly stop #{channel} channel: #{e.message}" if debug?
      ensure
        @channels.delete(channel)
      end
    end

    # Set a channel volume
    # @param channel [Symbol] channel to set the volume
    # @param volume [Integer] volume of the channel (0~100)
    def set_channel_volume(channel, volume)
      synchronize(@mutexes[channel]) do
        c = @channels[channel]
        c&.setVolume(volume / 100.0)
      end
    rescue FMOD::Error => e
      puts "Failed to set #{channel} channel volume: #{e.message}" if debug?
      @channels.delete(channel) # It's safe to delete the channel if this simple operation fails
    end

    # Get a channel audio position
    # @param channel [Symbol]
    # @return [Integer] channel audio position in driver's unit
    def get_channel_audio_position(channel)
      synchronize(@mutexes[channel]) do
        c = @channels[channel]
        return c.getPosition(FMOD::TIMEUNIT::PCM) if c
      end
      return 0
    rescue FMOD::Error => e
      puts "Failed to get #{channel} channel position: #{e.message}" if debug?
      @channels.delete(channel) # It's safe to delete the channel if this simple operation fails
      return 0
    end

    # Set a channel audio position
    # @param channel [Symbol]
    # @param position [Integer] audio position in driver's unit
    def set_channel_audio_position(channel, position)
      synchronize(@mutexes[channel]) do
        c = @channels[channel]
        c&.setPosition(position, FMOD::TIMEUNIT::PCM)
      end
    rescue FMOD::Error => e
      puts "Failed to set #{channel} channel position: #{e.message}" if debug?
    end

    # Mute a channel for an amount of time
    # @param channel [Symbol]
    # @param duration [Integer] mute duration in driver's time
    def mute_channel_for(channel, duration)
      synchronize(@mutexes[channel]) do
        c = @channels[channel]
        c&.setDelay(c.getDSPClock.last + duration, 0, false)
      end
    rescue FMOD::Error => e
      puts "Failed to mute #{channel} channel: #{e.message}" if debug?
    end

    # Unmute a channel
    # @param channel [Symbol]
    def unmute_channel(channel)
      synchronize(@mutexes[channel]) do
        c = @channels[channel]
        c&.setDelay(0, 0, false)
      end
    rescue FMOD::Error => e
      puts "Failed to un-mute #{channel} channel: #{e.message}" if debug?
    end

    # Get a channel duration
    # @param channel [Symbol]
    # @return [Integer]
    def get_channel_duration(channel)
      sound = @sounds[channel]
      return 0 unless sound

      return sound.getLength(FMOD::TIMEUNIT::PCM)
    rescue FMOD::Error => e
      puts "Failed to get #{channel} channel duration: #{e.message}" if debug?
      return 0
    end

    private

    # Play a music (looped)
    # @param channel [Symbol] channel for the music (:bgm, :bgs)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    # @param fade_with_previous [Boolean] if the previous music should be faded with this one
    def play_music_internal(channel, filename, volume, pitch, fade_with_previous)
      was_playing = was_sound_previously_playing?(filename, @names[channel], sound = @sounds[channel], @channels[channel], fade_with_previous)
      @names[channel] = filename
      fade_in = (fade_with_previous && sound && !was_playing)
      release_fading_sounds((was_playing || fade_in) ? nil : sound)
      # Unless the sound was playing, we create it
      unless was_playing
        @sounds[channel] = @channels[channel] = nil
        return unless (sound = @sounds[channel] = create_sound_sound(filename))
        auto_loop(@sounds[channel])
      end
      @channels[channel] = FMOD::System.playSound(sound, true) unless was_playing && @channels[channel]
      c = @channels[channel]
      adjust_channel(c, channel, volume, pitch)
      fade(fade_in == true ? FADE_IN_TIME : fade_in, c, 0, 1.0) if fade_in
      @fading_sounds.delete(sound)
    rescue FMOD::Error
      log_error("Le fichier #{filename} n'a pas pu être lu...\nErreur : #{$!.message}")
      stop_channel(channel)
    ensure
      call_was_playing_callback
    end

    # Play a ME
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    def play_me_sound(filename, volume, pitch)
      was_playing = was_sound_previously_playing?(filename, @names[:me], sound = @sounds[:me], @channels[:me])
      @names[:me] = filename
      release_fading_sounds(was_playing ? nil : sound)
      # Unless the sound was playing, we create it
      unless was_playing
        @sounds[:me] = @channels[:me] = nil
        return unless (sound = @sounds[:me] = create_sound_sound(filename, FMOD::MODE::LOOP_OFF | FMOD::MODE::FMOD_2D))
      end
      # we create a channel if there was no channel or the sound was not playing
      c = @channels[:me] = FMOD::System.playSound(sound, true)
      adjust_channel(c, :me, volume, pitch)
      @fading_sounds.delete(sound) # Reused channel error prevention
    rescue FMOD::Error
      log_error("Le fichier #{filename} n'a pas pu être lu...\nErreur : #{$!.message}")
      stop_channel(:me)
    ensure
      call_was_playing_callback
    end

    # Play a SE
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    def play_se_sound(filename, volume, pitch)
      unless (sound = @se_sounds[filename])
        return unless (sound = create_sound_sound(filename, FMOD::MODE::LOOP_OFF | FMOD::MODE::FMOD_2D))
        if filename.downcase.include?('/cries/')
          @cries_stack << sound
          @cries_stack.shift.release if @cries_stack.size > 5
        else
          @se_sounds[filename] = sound
        end
      end
      c = FMOD::System.playSound(sound, true)
      adjust_channel(c, filename.include?('/cries/') ? :cries : :se, volume, pitch)
    rescue FMOD::Error => e
      if e.message.sub('FmodError ', '').to_i == 46
        @se_sounds.delete(filename)
        retry
      else
        log_error("Failed to play se #{filename}")
      end
    end

    # Get all the supported extensions
    # @return [Array<String>]
    def audio_filename_extensions
      AUDIO_FILENAME_EXTENSIONS
    end

    # Auto loop a music
    # @param sound [FMOD::Sound] the sound that contain the data
    # @note Only works with createSound and should be called before the channel creation
    def auto_loop(sound)
      start = sound.getTag('LOOPSTART', 0)[2].to_i rescue nil
      length = sound.getTag('LOOPLENGTH', 0)[2].to_i rescue nil
      unless start && length # Probably an MP3
        index = 0
        while (tag = sound.getTag('TXXX', index) rescue nil)
          index += 1
          next unless tag[2].is_a?(String)
          name, data = tag[2].split("\x00")
          if name == 'LOOPSTART' && !start
            start = data.to_i
          elsif name == 'LOOPLENGTH' && !length
            length = data.to_i
          end
        end
      end
      return unless start && length
      log_info "LOOP: #{start} -> #{start + length}" unless PSDK_CONFIG.release?
      sound.setLoopPoints(start, FMOD::TIMEUNIT::PCM, start + length, FMOD::TIMEUNIT::PCM)
    end

    # Fade a channel
    # @param time [Integer] number of miliseconds to perform the fade
    # @param channel [FMOD::Channel] the channel to fade
    # @param start_value [Numeric]
    # @param end_value [Numeric]
    def fade(time, channel, start_value = 1.0, end_value = 0)
      sr = FMOD::System.getSoftwareFormat.first
      pdsp = channel.getDSPClock.last
      stop_time = pdsp + Integer(time * sr / 1000)
      channel.addFadePoint(pdsp, start_value)
      channel.addFadePoint(stop_time, end_value)
      channel.setDelay(0, stop_time + 20, false) if end_value == 0
      channel.setVolumeRamp(true)
      channel.instance_variable_set(:@stop_time, stop_time)
    end

    # Try to release all fading sounds that are done fading
    # @param additionnal_sound [FMOD::Sound, nil] a sound that should be released with the others
    # @note : Warning ! Doing sound.release before channel.anything make the channel invalid and raise an FMOD::Error
    def release_fading_sounds(additionnal_sound)
      unless @fading_sounds.empty?
        sound_guardian = Audio.music_channels.map { |c| @sounds[c] }.concat(Audio.sfx_channels.map { |c| @sounds[c]})
        sounds_to_delete = []
        @fading_sounds.each do |sound, channel|
          additionnal_sound = nil if additionnal_sound == sound
          next unless channel_stop_time_exceeded(channel)
          sounds_to_delete << sound
          channel.stop
          next if sound_guardian.include?(sound)
          sound.release
        rescue FMOD::Error
          next # Next iteration if channel.stop failed
        end
        sounds_to_delete.each { |sound| @fading_sounds.delete(sound) }
      end
      additionnal_sound&.release
    end

    # Return if the channel time is higher than the stop time
    # @note will return true if the channel handle is invalid
    # @param channel [FMOD::Channel]
    # @return [Boolean]
    def channel_stop_time_exceeded(channel)
      return channel.getDSPClock.last >= channel.instance_variable_get(:@stop_time).to_i
    rescue FMOD::Error
      return true
    end

    # Synchronize a mutex
    # @param mutex [Mutex] the mutex to safely synchronize
    # @param block [Proc] the block to call
    def synchronize(mutex, &block)
      return yield if mutex.locked? && mutex.owned?
      mutex.synchronize(&block)
    end

    # Create a bgm sound used to play the BGM
    # @param filename [String] the correct filename of the sound
    # @param flags [Integer, nil] the FMOD flags for the creation
    # @return [FMOD::Sound] the sound
    def create_sound_sound(filename, flags = nil)
      file_data = try_load(filename)
      return nil unless file_data

      audio_filename = search_audio_filename(filename)
      gm_filename = audio_filename.include?('.mid') && File.exist?('gm.dls') ? 'gm.dls' : nil
      sound_info = FMOD::SoundExInfo.new(file_data.bytesize, nil, nil, nil, nil, nil, gm_filename)
      sound = FMOD::System.createSound(file_data, create_sound_get_flags(flags), sound_info)
      sound.instance_variable_set(:@extinfo, sound_info)
      return sound
    end

    # Return the expected flag for create_sound_sound
    # @param flags [Integer, nil] the FMOD flags for the creation
    # @return [Integer]
    def create_sound_get_flags(flags)
      return (flags | FMOD::MODE::OPENMEMORY | FMOD::MODE::CREATESTREAM) if flags
      return (FMOD::MODE::LOOP_NORMAL | FMOD::MODE::FMOD_2D | FMOD::MODE::OPENMEMORY | FMOD::MODE::CREATESTREAM)
    end

    # Function that detects if the previous playing sound is the same as the next one
    # @param filename [String] the filename of the sound
    # @param old_filename [String] the filename of the old sound
    # @param sound [FMOD::Sound] the previous playing sound
    # @param channel [FMOD::Channel, nil] the previous playing channel
    # @param fade_out [Boolean, Integer] if the channel should fades out (Integer = time to fade)
    # @note If the sound wasn't the same, the channel will be stopped if not nil
    # @return [Boolean]
    def was_sound_previously_playing?(filename, old_filename, sound, channel, fade_out = false)
      return false unless sound
      return true unless filename.downcase != old_filename.downcase
      return false unless channel && (channel.isPlaying rescue false)

      if fade_out && !@fading_sounds[sound]
        fade_time = fade_out == true ? FADE_IN_TIME : fade_out
        @was_playing_callback = proc { fade(fade_time, @fading_sounds[sound] = channel) }
      else
        @was_playing_callback = proc { channel.stop }
      end
      return false
    end

    # Adjust channel volume and pitch
    # @param channel [Fmod::Channel]
    # @param channel_type [Symbol]
    # @param volume [Numeric] target volume
    # @param pitch [Numeric] target pitch
    def adjust_channel(channel, channel_type, volume, pitch)
      channel.setPriority(AUDIO_PRIORITIES[channel_type] || 128)
      channel.setVolume(volume / 100.0)
      channel.setPitch(pitch / 100.0)
      channel.setPaused(false)
    end

    # Automatically call the "was playing callback"
    def call_was_playing_callback
      @was_playing_callback&.call
      @was_playing_callback = nil
    rescue StandardError
      @was_playing_callback = nil
    end
  end

  register_driver(:fmod, FMODDriver) if Object.const_defined?(:FMOD)
end
