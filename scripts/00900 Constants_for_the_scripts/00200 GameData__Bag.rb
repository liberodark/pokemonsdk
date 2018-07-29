#encoding: utf-8

module GameData
  # Module that holds constants related to the bag
  module Bag
    # Maximum amount of a specific item allowed in the bag
    MaxItem = 99
    module_function
    # Return the socket name
    # @param socket [Integer] id of the socket
    # @return [String]
    def get_socket_name(socket)
      case socket
      when 1
        return _get(15, 0)
      when 2
        return "Pokéball"
      when 3
        return _get(15, 2)
      when 4
        return _get(15, 3)
      when 5
        return _get(15, 4)
      when 6
        return _get(15, 1)
      end
      return _get(15, 0)
    end
  end
end
