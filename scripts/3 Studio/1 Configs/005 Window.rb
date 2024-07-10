module Configs
  # Configuration of window
  #
  # Every window builder should be Array of integer like this
  #    ConstName = [middle_tile_x, middle_tile_y, middle_tile_width, middle_tile_height,
  #                 contents_offset_left, contents_offset_top, contents_offset_right, contents_offset_bottom]
  class Window
    # All message frames with their names
    # @return [Hash<Symbol => String>]
    attr_accessor :message_frames

    # All the window builder
    # @return [Hash<Symbol => Array>]
    attr_accessor :builders

    def initialize
      @message_frames = {
        message: 'X/Y',
        m_1: 'Gold',
        m_2: 'Silver',
        m_3: 'Red',
        m_4: 'Blue',
        m_5: 'Green',
        m_6: 'Orange',
        m_7: 'Purple',
        m_8: 'Heart Gold',
        m_9: 'Soul Silver',
        m_10: 'Rocket',
        m_11: 'Blue Indus',
        m_12: 'Red Indus',
        m_13: 'Swamp',
        m_14: 'Safari',
        m_15: 'Brick',
        m_16: 'Sea',
        m_17: 'River',
        m_18: 'B/W'
      }

      @builders = {
        generic: [16, 16, 8, 8, 16, 8],
        message_box: [14, 7, 8, 8, 16, 8]
      }
    end

    # Get all the message frame filenames
    # @return [Array<String>]
    def message_frame_filenames
      @message_frame_filenames ||= @message_frames.keys.map(&:to_s)
    end

    # Get all the message frame names
    # @return [Array<String>]
    def message_frame_names
      @message_frame_names ||= @message_frames.values.map { |s| s.is_a?(String) ? s : text_get(*s) }
    end

    # Convert the config to json
    def to_json(*)
      {
        klass: self.class.to_s,
        message_frames: @message_frames,
        builders: @builders
      }.to_json
    end
  end
  # @!method self.window
  #   @return [Window]
  register(:window, 'window', :json, false, Window)
end

# Load all the window colors
Graphics.on_start do
  # We load the color info image
  RPG::Cache.load_windowskin
  # @type [Yuki::VD, nil]
  windowskin_vd = RPG::Cache.instance_variable_get(:@windowskin_data)
  data = windowskin_vd&.read_data('_colors')
  # We load the color image, the `data ? true : false` is wanted because of the internal functions
  # @type [Image]
  color_image = data ? Image.new(data, true) : Image.new('graphics/windowskins/_colors.png')
  color_image.width.times do |i|
    Fonts.define_outline_color(i, color_image.get_pixel(i, 0))
    Fonts.define_fill_color(i, color_image.get_pixel(i, 1))
    Fonts.define_shadow_color(i, color_image.get_pixel(i, 2))
  end
end
