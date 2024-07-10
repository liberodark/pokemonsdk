# Module responsive of handling audio in game
module Audio
  # Base class for all audio drivers (mainly definition)
  class DriverBase
    # List of all the audio filename that were already logged due to being missing
    @@logged_audio_filenames = []
    # List of the Audio extension that are supported
    AUDIO_FILENAME_EXTENSIONS = ['.ogg', '.mp3', '.wav', '.flac']
    # Update the driver (must be called every meaningful frames)
    def update
    end

    # Reset the driver
    def reset
    end

    # Release the driver
    def release
    end

    # Play a sound (just once)
    # @param channel [Symbol] channel for the sound (:se, :me)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    def play_sound(channel, filename, volume, pitch)
    end

    # Play a music (looped)
    # @param channel [Symbol] channel for the music (:bgm, :bgs)
    # @param filename [String] name of the sound
    # @param volume [Integer] volume of the sound (0~100)
    # @param pitch [Integer] pitch of the sound (50~150)
    # @param fade_with_previous [Boolean] if the previous music should be faded with this one
    def play_music(channel, filename, volume, pitch, fade_with_previous)
    end

    # Fade a channel out
    # @param channel [Symbol] channel to fade
    # @param duration [Integer] duration of the fade out in ms
    def fade_channel_out(channel, duration)
    end

    # Stop a channel
    # @param channel [Symbol] channel to stop
    def stop_channel(channel)
    end

    # Set a channel volume
    # @param channel [Symbol] channel to set the volume
    # @param volume [Integer] volume of the channel (0~100)
    def set_channel_volume(channel, volume)
    end

    # Get a channel audio position
    # @param channel [Symbol]
    # @return [Integer] channel audio position in driver's unit
    def get_channel_audio_position(channel)
      return 0
    end

    # Set a channel audio position
    # @param channel [Symbol]
    # @param position [Integer] audio position in driver's unit
    def set_channel_audio_position(channel, position)
    end

    # Mute a channel for an amount of time
    # @param channel [Symbol]
    # @param duration [Integer] mute duration in driver's time
    def mute_channel_for(channel, duration)
    end

    # Unmute a channel
    # @param channel [Symbol]
    def unmute_channel(channel)
    end

    # Get a channel duration
    # @param channel [Symbol]
    # @return [Integer]
    def get_channel_duration(channel)
      return 0
    end

    private

    # Load an Audio file content
    # @param filename [String]
    # @return [String, nil]
    def try_load(filename)
      audio_filename = search_audio_filename(filename)
      return File.binread(audio_filename) if File.exist?(audio_filename)
      return nil if @@logged_audio_filenames.include?(filename)

      log_error("FATAL ERROR: No such file or directory #{filename}")
      @@logged_audio_filenames << filename
      return nil
    end

    # Find the audio filename
    # @param filename [String]
    # @return [String]
    def search_audio_filename(filename)
      return filename if File.exist?(filename)

      lower_filename = filename.downcase
      return lower_filename if File.exist?(lower_filename)

      return audio_filename_extensions.filter_map do |ext|
        audio_filename = lower_filename + ext
        next audio_filename if File.exist?(audio_filename)
      end.first || filename
    end

    # Get all the supported extensions
    # @return [Array<String>]
    def audio_filename_extensions
      AUDIO_FILENAME_EXTENSIONS
    end
  end
end
