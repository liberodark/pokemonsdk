module Studio
  # Data class describing a worldmap
  class WorldMap
    # ID of the worldmap
    # @return [Integer]
    attr_reader :id

    # db_symbol of the worldmap
    # @return [Symbol]
    attr_reader :db_symbol

    # Image filename of the worldmap
    # @return [String]
    attr_reader :image

    # Grid of the worldmap (2D array of zone id)
    # @return [Array]
    attr_reader :grid

    # Get the region name
    # @return [CSVAccess]
    attr_reader :region_name

    # Name of the region
    # @return [String]
    def name
      region_name.get
    end
  end

  # Data class describing a CSV access
  class CSVAccess
    # ID of the csv file
    # @return [Integer]
    attr_reader :file_id

    # Index of the text in CSV file
    # @return [Integer]
    attr_reader :text_index

    # Get the text
    # @return [String]
    def get
      text_get(@file_id, @text_index)
    end
  end
end
