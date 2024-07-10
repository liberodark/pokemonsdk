module Studio
  # Data class describing a type
  class Type
    # ID of the type
    # @return [Integer]
    attr_reader :id

    # db_symbol of the type
    # @return [Symbol]
    attr_reader :db_symbol

    # ID of the text of the type in the text files
    # @return [Integer]
    attr_reader :text_id

    # List of damage the type deals to another type
    # @return [Array<DamageTo>]
    attr_reader :damage_to

    # Color of the type
    # @return [Color, nil]
    attr_reader :color

    # Get the text name of the type
    # @return [String]
    def name
      return text_get(3, @text_id)
    end

    # Get the modifier of this type when hitting another type
    # @param other_type [Symbol] db_symbol of the other type
    # @return [Float]
    def hit(other_type)
      return damage_to.find { |damage| damage.defensive_type == other_type }&.factor || 1
    end

    # Data class describing the damage a type does against another type
    class DamageTo
      # Defensive type getting the damage factor
      # @return [Symbol]
      attr_reader :defensive_type

      # Factor of damage over the defensive type
      # @return [Float]
      attr_reader :factor
    end
  end
end
