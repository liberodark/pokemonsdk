class Game_Character
  # The current move route
  attr_reader :move_route
  # The current move route index
  attr_reader :move_route_index
  # The bridge state
  attr_accessor :__bridge
  # The current sliding state
  attr_accessor :sliding
  # The current surfing state
  attr_writer :surfing
  # The current path
  # @return [Array<RPG::MoveCommand>, :pending, nil]
  attr_accessor :path

  # Move route that is empty and serve as a template for all the generate move route (by Path Finding)
  EMPTY_MOVE_ROUTE = RPG::MoveRoute.new
  EMPTY_MOVE_ROUTE.repeat = false

  # Request a path to the target and follow it as soon as it found
  # @param to [Array<Integer, Integer>, Game_Character] the target, [x, y] or Game_Character object
  # @param radius [Integer] <default : 0> the distance from the target to consider it as reached
  # @param tries [Integer, Symbol] <default : 5> the number of tries allowed to this request, use :infinity to unlimited try count
  # @param type [Symbol]
  # @example find path to x=10 y=15 with an error radius of 5 tiles
  #   find_path(to:[10,15], radius:5)
  def find_path(to:, radius: 0, tries: Pathfinding::TRY_COUNT, type: nil)
    # Wrap data to match
    type ||= (to.is_a?(Array) ? :Coords : :Character)
    # Create the request
    Pathfinding.add_request(self, [type, to, radius], tries, :DEFAULT)
    # Set move route forcing to true
    @move_route_forcing_path_finder ||= @move_route_forcing
    @move_route_forcing = true
    @move_type_custom_special_result = true
  end

  # Stop following the path if there is one and clear the agent
  def stop_path
    # force_move_route(EMPTY_MOVE_ROUTE)
    clear_path
    Pathfinding.remove_request(self)
  end

  # Movement induced by the Path Finding
  def move_type_path
    return if @path == :pending
    return unless movable?
    while (command = @path[@move_route_index])
      # @move_route_index += 1
      break if move_type_custon_exec_command(command)
    end
  end

  # Define the path from path_finding
  # @param path [Array<RPG::MoveCommand>]
  def define_path(path)
    @move_route_index_path_finder ||= @move_route_index
    @move_route_index = 0
    @path = path
  end

  private

  # Clear the path
  def clear_path
    @move_route_index = @move_route_index_path_finder if @move_route_index_path_finder
    @move_route_forcing = @move_route_forcing_path_finder if @move_route_index_path_finder
    @move_route_index_path_finder = @path = @move_route_forcing_path_finder = nil
  end
end
