module Studio
  # Data class describing a zone (set of map under the same name, group etc...)
  class Zone
    # ID of the zone
    # @return [Integer]
    attr_reader :id

    # db_symbol of the zone
    # @return [Symbol]
    attr_reader :db_symbol

    # List of maps included in this zone
    # @return [Array<Integer>]
    attr_reader :maps

    # List of worldmap included in this zone
    # @return [Array<Integer>]
    attr_reader :worldmaps

    # ID of the panel to show when entering the zone (0 = none)
    # @return [Integer]
    attr_reader :panel_id

    # Target warp coordinates when using Dig, Fly or Teleport
    # @return [MapCoordinate]
    attr_reader :warp

    # Default position of the zone on the worldmap
    # @return [MapCoordinate]
    attr_reader :position

    # If the player can use fly, otherwise use dig
    # @return [Boolean]
    attr_reader :is_fly_allowed

    # If the player cannot use any teleportation method (fly, dig, teleport)
    # @return [Boolean]
    attr_reader :is_warp_disallowed

    # ID of the weather to automatically trigger
    # @return [Integer, nil]
    attr_reader :forced_weather

    # List of wild group db_symbol included on this map
    # @return [Array<Symbol>]
    attr_reader :wild_groups

    # Get the zone name
    # @return [String]
    def name
      return text_get(10, @id)
    end

    # Data class describing a map coordinate
    class MapCoordinate
      # Get the x position
      # @return [Integer]
      attr_reader :x

      # Get the y position
      # @return [Integer]
      attr_reader :y
    end
  end
end
