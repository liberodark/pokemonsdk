module Studio
  # Data class describing an Ability
  class Ability
    # ID of the ability
    # @return [Integer]
    attr_reader :id

    # db_symbol of the ability
    # @return [Symbol]
    attr_reader :db_symbol

    # ID of the text of the ability in the text files
    # @return [Integer]
    attr_reader :text_id

    # Get the text description of the ability
    # @return [String]
    def description
      return text_get(5, @text_id)
    end
    alias descr description

    # Get the text name of the ability
    # @return [String]
    def name
      return text_get(4, @text_id)
    end
  end
end
