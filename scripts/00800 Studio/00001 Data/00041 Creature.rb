module Studio
  # Data class describing a creature
  class Creature
    # ID of the specie
    # @return [Integer]
    attr_reader :id

    # db_symbol of the specie
    # @return [Symbol]
    attr_reader :db_symbol

    # all the form of the creature
    # @return [Array<CreatureForm>]
    attr_reader :forms

    # Get the creature name
    # @return [String]
    def name
      return text_get(0, @id)
    end

    # Get the specie name
    # @return [String]
    def species
      return text_get(1, @id)
    end

    # Get the creature description
    # @return [String]
    def description
      return text_get(2, @id)
    end
    alias descr description
  end
end
