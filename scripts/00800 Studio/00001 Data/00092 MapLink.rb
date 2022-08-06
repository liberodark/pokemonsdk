module Studio
  # Data class describing a map link
  #
  # @note This class has an id and a map_id, this leaves room to add conditional map links in the future ;)
  class MapLink
    # ID of the map link
    # @return [Integer]
    attr_reader :id

    # db_symbol of the map link
    # @return [Symbol]
    attr_reader :db_symbol

    # ID of the map player should be in to have this link
    # @return [Integer]
    attr_reader :map_id

    # List of maps linked to the north cardinal of current map
    # @return [Array<Link>]
    attr_reader :north_maps

    # List of maps linked to the east cardinal of current map
    # @return [Array<Link>]
    attr_reader :east_maps

    # List of maps linked to the south cardinal of current map
    # @return [Array<Link>]
    attr_reader :south_maps

    # List of maps linked to the west cardinal of current map
    # @return [Array<Link>]
    attr_reader :west_maps

    # Class describing how map is linked to current map with its offset and its id
    class Link
      # ID of the map linked to current map
      # @return [Integer]
      attr_reader :map_id

      # Offset to the right or bottom depending on which cardinal the map is
      # @return [Integer]
      attr_reader :offset
    end
  end
end
