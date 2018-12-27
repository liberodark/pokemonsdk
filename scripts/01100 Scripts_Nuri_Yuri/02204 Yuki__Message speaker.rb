module Yuki
  class Message
    private

    INFO_NAME = 'name='
    INFO_FACE = 'face='
    # Parse the speakers information
    # @param info_str [String] string containing all the informations
    # @example example of info_str
    #   name=Yuri the scripter;face=0,032;face=-64,026,128
    #   The speaker will be Yuri the scripter
    #   His face will be Graphics/Battlers/032.png
    #   His face will be shown at the coordinate x = 0 (centered)
    #   Another face is shown at the coordinate x = Viewport.width - 64
    #   This face will be Graphics/Battlers/026.png
    #   This face will have the opacity 128
    #   Note : The face order is important, the first defined will be below the second one
    def parse_speaker(info_str)
      @face_stack.dispose
      info_str.split(';').each do |sub_info_str|
        if sub_info_str.start_with?(INFO_NAME)
          parse_speaker_name(sub_info_str.split('=').last)
        elsif sub_info_str.start_with?(INFO_FACE)
          parse_speaker_face(sub_info_str.split('=').last)
        end
      end
      viewport.sort_z
      self.face_opacity = opacity
      nil
    end

    # Parse the speaker name
    # @param name [String] name of the speaker
    def parse_speaker_name(name)
      @name_window.visible = true
      @name_window.lock
      @name_window.set_origin(0, 0)
      @name_window.width = @name_text.text_width(name) + 2 * @name_window.window_builder[4]
      @name_window.unlock
      @name_text.text = name
    end

    # Parse the face of a speaker
    # @param info_str [String] infos about the face (position,name,opacity,mirror)
    def parse_speaker_face(info_str)
      position, name, opacity, mirror = info_str.split(',')
      position = position.to_i
      # Parse the negative position
      position = viewport.rect.width + position if position < 0
      sprite = @face_stack.push(position, face_speaker_y, name.to_s)
      sprite.set_origin(sprite.width / 2, sprite.height)
      sprite.opacity = opacity.to_i if opacity
      sprite.mirror = mirror == 'true'
      sprite.instance_variable_set(:@opacity, sprite.opacity)
    end

    # Update the value of the face opacity
    def face_opacity=(value)
      @face_stack.stack.each do |sprite|
        sprite.opacity = value * sprite.instance_variable_get(:@opacity) / 255
      end
    end

    # Return the face_speaker y position
    # @return [Integer]
    def face_speaker_y
      return viewport.rect.height # if position == :top
      # y
    end
  end
end