module Studio
  # Data class describing an Quest
  class Quest
    # ID of the quest
    # @return [Integer]
    attr_reader :id

    # db_symbol of the quest
    # @return [Symbol]
    attr_reader :db_symbol

    # Is the quest primary
    # @return [Boolean]
    attr_reader :is_primary

    # Kind of quest resolution process (:default or :progressive)
    # @return [Symbol]
    attr_reader :resolution

    # List of objective to complete the quest
    # @return [Array<Objective>]
    attr_reader :objectives

    # List of all the earning from completing the quest
    # @return [Array<Earning>]
    attr_reader :earnings

    # Get the text description of the ability
    # @return [String]
    def description
      return text_get(46, @id)
    end
    alias descr description

    # Get the text name of the ability
    # @return [String]
    def name
      return text_get(45, @id)
    end

    # Data class describing a quest objective
    class Objective
      # Name of the method to call to validate the objective
      # @return [Symbol]
      attr_reader :objective_method_name

      # Arguments of the method to call
      # @return [Array]
      attr_reader :objective_method_args

      # Name of the method to call in order to get the text to show in UI
      # @return [Symbol]
      attr_reader :text_format_method_name

      # If the objective is hidden by default
      # @return [Boolean]
      attr_reader :hidden_by_default
    end

    # Data class describing a quest earning
    class Earning
      # Name of the method to call to give the earning to player
      # @return [Symbol]
      attr_reader :earning_method_name

      # Argument of the method to call
      # @return [Array]
      attr_reader :earning_args

      # Name of the method to call in order to get the text to show in UI
      # @return [Symbol]
      attr_reader :text_format_method_name
    end
  end
end
