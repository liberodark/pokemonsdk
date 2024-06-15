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

    # Function responsive of making sure that tilesets and @map_to_tileset are somewhate coherent
    def auto_fix_tilesets
      # No fixup if the @map_to_tileset is empty
      return if @map_to_tileset.empty?

      tileset_ids = @map_to_tileset.values
      max_tileset_id = tileset_ids.max
      # Remap tileset ids to ensure there is no duplicate (set duplicate to max_tileset_id + 1)
      tileset_ids = tileset_ids.map.with_index do |id, index|
        if tileset_ids.index(id) != index
          max_tileset_id += 1
          next max_tileset_id
        end
        next id
      end
      # Rebuild the @map_to_tileset with new tileset_ids table
      @map_to_tileset = @map_to_tileset.keys.zip(tileset_ids).to_h
      # Fill the tilesets table until all ids are set (fixup the undefined method #name= issue)
      TILESETS << TILESETS[1].dup while TILESETS.size <= max_tileset_id
      # Ensure the load function gets
      return self
    end

    class << self
      # Load the settings
      # @return [Settings]
      def load
        (File.exist?(FILENAME) ? load_data(FILENAME) : new).auto_fix_tilesets
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
