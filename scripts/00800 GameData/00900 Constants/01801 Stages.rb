module GameData
  # Battle stages index
  module Stages
    ATK = 0
    ATS = 3
    DFE = 1
    DFS = 4
    SPD = 2
    EVA = 5
    ACC = 6

    module_function

    # Find the symbol of a Stage according to the Stage id
    # @param value [Integer] Stage id
    # @return [Symbol]
    def index(value)
      constants.find { |const_name| const_get(const_name) == value } || :__undef__
    end
  end
end
