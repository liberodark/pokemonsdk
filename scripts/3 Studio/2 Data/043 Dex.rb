module Studio
  # Data class describing a dex
  class Dex
    # Get the db_symbol of the dex
    # @return [Symbol]
    attr_reader :db_symbol

    # Get the ID of the dex
    # @return [Integer]
    attr_reader :id

    # Get the start id of each creature in the dex
    # @return [Integer]
    attr_reader :start_id

    # Get the list of creature in the dex
    # @return [Array<CreatureInfo>]
    attr_reader :creatures

    # Get the dex name
    # @return [CSVAccess]
    attr_reader :csv

    # Get the name of the dex
    # @return [String]
    def name
      return csv.get
    end

    # Data class describing a creature info in the dex
    class CreatureInfo
      # Get the db_symbol of the creature
      # @return [Symbol]
      attr_reader :db_symbol

      # Get the form of the creature
      # @return [Integer]
      attr_reader :form
    end
  end
end
