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

  EMPTY_MOVE_ROUTE = RPG::MoveRoute.new
  EMPTY_MOVE_ROUTE.repeat = false

  # Request a path to the target and follow it as soon as it found
  def find_path(to:,radius: 0, priority: Pathfinding::PRIORITY_NORMAL, tries: Pathfinding::TRY_COUNT, type: nil)
    type = (to.is_a?(Array) ? :coords : :character) unless type
    unless Pathfinding.add_request(self, [type, to, radius], priority, tries)
      pc "PATHFINDING >>> Can't submit the request of #{self}"
    end
  end

  # Stop following the path if there is one and clear the agent
  def stop_path
    # move_type_custom_end # Stop the custom route
    force_move_route(EMPTY_MOVE_ROUTE)
    pc "PATHFINDING >>> Can't remove the request (#{self})" unless Pathfinding.remove_request(self)
  end
end
