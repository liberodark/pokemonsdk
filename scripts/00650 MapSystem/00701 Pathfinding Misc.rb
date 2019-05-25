# Pathfinding (PSDK) by Leikt

class Interpreter
  # Shortcut for get_character(@event_id).find_path(*args)
  # Exemple : find_path to:[10,15], radius:5
  # @param to: [Array<Integer, Integer>, Game_Character] the target, [x, y] or Game_Character object
  # @param radius: [Integer] <default : 0> the distance from the target to consider it as reached
  # @param priority: [Integer] <default : Pathfinding::PRIORITY_NORMAL> the priority in front of the other requests
  # @param tries: [Integer, Symbol] <default : 5> the number of tries allowed to this request, use :infinity to unlimited tris count
  def find_path(*args)
    get_character(@event_id).find_path(*args)
  end
end

# Class that describe and manipulate the Game Characters
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

  # Request a path to the target and follow it as soon as it found
  def find_path(to:,radius: 0, priority: Pathfinding::PRIORITY_NORMAL, tries: Pathfinding::TRY_COUNT)
    unless Pathfinding.add_request(self, [to, radius], priority, tries)
      pc "PATHFINDING >>> Can't submit the request of #{self}"
    end
  end

  # Stop following the path if there is one and clear the agent
  def stop_path
    move_type_custom_end # Stop the custom route
    pc "PATHFINDING >>> Can't remove the request (#{self})" unless Pathfinding.remove_request(self)
  end
end
