module Tiled2Rxdata
  # Entity holding the converter settings (so it knows what are the expected tileset id for each map)
  class Settings
    # Name of the settings file on the disk
    FILENAME = 'Data/Tiled/.jobs/settings.rxdata'

    # Create a new Settings object
    def initialize
      @map_to_tileset = {}
    end

    # Get the ID of a tileset from the ID of a map
    # @param map_id [Integer]
    # @return [Integer]
    def tileset_id(map_id)
      unless id = @map_to_tileset[map_id]
        id = TILESETS.size
        TILESETS[id] = tileset = TILESETS[1].dup
        tileset.id = id
        @map_to_tileset[map_id] = id
        return id
      end
      return id
    end

    class << self
      # Load the settings
      # @return [Settings]
      def load
        File.exist?(FILENAME) ? load_data(FILENAME) : new
      end

      # Save the settings
      def save
        @self && File.binwrite(FILENAME, Marshal.dump(@self))
      end

      # Get the settings
      # @return [Settings]
      def get
        @self ||= load
      end
    end
  end
end
