module GameData
  # Data structure of world maps
  # @author Leikt, Nuri Yuri
  class WorldMap < Base
    # Filename of the image used to display the world map
    # @return [String]
    attr_accessor :image
    # Surface of the image used to display the world map
    # @return [Rect]
    attr_accessor :surface
    # Informations on the map
    # @return [Table,Array<WorldMapObject>]
    attr_accessor :data
    # Create a new GameData::WorldMap
    def initialize(background_image, image, surface, data)
      @image = image
      @surface = surface
      @data = data
    end
    
    # Load the data for the worldmap into a wrapper and return it.
    # @param wm_id [Integer] the id of the world map to load
    # @return [GameData::WorldMap::Wrapper]
    def self.data_zone(wm_id)
      return GameData::WorldMap::Wrapper.new($game_data_worldmap[map_id].data)
    end

    # Class that wrap the world map data to GamePlay::WorldMap data
    # @author Leikt, Nuri Yuri
    class Wrapper
      # Create the wrapper
      # @param [GameData::WorldMap]
      def initialize(wm_data)
        @data = wm_data
        @type = wm_data.is_a?(Array) ? :object : :grid
      end

      # Get the zone of the cursor and return the id of it. Return -1 if no zone.
      # @param x [Integer] cursor's x coord (pixel)
      # @param y [Integer] cursor's y coord (pixel)
      # @return [Integer]
      def get_zone(x, y)
        if @type == :grid
          return grid_get_zone(x, y)
        else
          return object_get_zone(x, y)
        end
      end

      private

      # To implement in a future update
      def object_get_zone(x, y)
        # TODO
        return -1
      end 

      #  Same as get_zone
      def grid_get_zone(x, y)
        # Wrap the cursor coords into grid coords
        return @data[x / GamePlay::WorldMap::TileSize][y / GamePlay::WorldMap::TileSize]
      end
    end
  end
end
