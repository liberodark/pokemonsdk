# Pathfinding (PSDK) by Leikt
# Module that handle the automatic pathfinding system.
# Djikstra Algorithm and optimized to be performance friendly.
# If you are experimenting performance issue while the algorithm is running, down the NODE_PER_FRAME value.
# You can customize the cost of each tag in TAGS_WEIGHT.

module Pathfinding
  # Amount of node to calculate in one frame (OPTIMISATION)
  NODES_PER_FRAME = 300
  # Amount of node by requests in one frame (OPTIMISATION)
  NODES_PER_REQUEST = 10
  # Obstacle detection range
  OBSTACLE_DETECTION_RANGE = 9
  # Amount of try count
  TRY_COUNT = 5
  # Number of frame before two path search when the first one fail
  TRY_DELAY = 60

  # Low priority
  PRIORITY_LOW = 0
  # Normal priority
  PRIORITY_NORMAL = 100
  # High priority
  PRIORITY_HIGH = 200
  # Player priority, above all other
  PRIORITY_PLAYER = 1000

  # Directions to check
  PATH_DIRS = [1,2,3,4]
  # Move route when waiting for a new path
  WAITING_ROUTE = RPG::MoveRoute.new
  WAITING_ROUTE.list.unshift(RPG::MoveCommand.new(15,1))

  # Weight of the tags, the higher is the cost, the more the path will avoid it
  TAGS_WEIGHT = {
    GameData::SystemTags::Road => 2,          # Tag of the main road
    GameData::SystemTags::SwampBorder => 20,  # Avoid swamp if possible
    GameData::SystemTags::DeepSwamp => 30,    # Avoid deep swamp whatever it takes
    GameData::SystemTags::MachBike => 1000,   # Prevent bug
  }
  TAGS_WEIGHT.default = 10 # Grass, ...

  # Initialisation
  0
  # List of requests looking for a path
  @requests = []
  # List of requests detecting obstacles
  @watching_requests = []
  # List of requests waiting before retry
  @waiting_requests = []
  # Last updated researching request
  @last_request_id = 0

  PRESET_COMMANDS = Array.new(5) {|i| RPG::MoveCommand.new(i)}.method(:[])
  # Convert a path to an RPG::MoveRoute
  # @param path [Array<Integer>] directions list
  # @return [RPG::MoveRoute]
  def self.path_to_route(path)
    route = RPG::MoveRoute.new # Init a non repeated route
    route.repeat = false
    # Create the list with empty command at the end
    path.push 0
    route.list = path.collect(&PRESET_COMMANDS)
    return route # Return the usable move route
  end

  # Add the request to the system list and start looking for path
  # @param character [Game_Character] the character looking for a path
  # @param target [Game_Character, Array<Integer>] character or coords to reach
  # @param priority [Integer] the priority of the request, use Pathfinding::PRIORITY_LOW / NORMAL / HIGH / PLAYER
  # @param tries [Integer] the number of tries before giving up the path research. :infinity for infinite try count.
  # @return [Boolean] if the request is successfully submitted
  def self.add_request(character, target, priority, tries)
    remove_request(character)
    @requests.push Request.new(character, Target.get(target), priority, tries)
    sort_requests
    return true
  end

  # Remove the request from the system list and return true if the request has been popped out.
  # @param character [Game_Character] the character to pop out
  # @return [Boolean] if the request has been popped out
  def self.remove_request(character)
    old_length = (@requests.length + @watching_requests.length)
    @requests.delete_if { |e| e.character == character }
    @watching_requests.delete_if { |e| e.character == character }
    @waiting_requests.delete_if { |e| e.character == character }
    @last_request_id = 0 # Reset the request id to prevent problems
    return (old_length > (@requests.length + @watching_requests.length))
  end

  # CLear all the requests
  def self.clear
    @requests.clone.each { |request| remove_request(request.character) }
    @watching_requests.clone.each { |request| remove_request(request.character) }
    @waiting_requests.clone.each { |request| remove_request(request.character) }
  end

  # Update the pathfinding system
  def self.update
    # Update the search
    # Initialize the update sequence
    node_counter = NODES_PER_FRAME    # Optimisation, only a certain amount of node can be search by frame
    current_id = @last_request_id     # Start this update at the same point than the last one
    until @requests.empty? || node_counter <= 0 # Continue the search until there is no requests left or to much node has been searched
      # current_request = @requests[current_id] # Get the request to update
      node_counter = (current_request=@requests[current_id]).update_search(node_counter) # Update the request and the node counter

      if current_request.watching? # If the current request is watching, add it to the watching list
        @watching_requests.push current_request
        @requests.delete(current_request)
      elsif current_request.waiting?
        @waiting_requests.push current_request
        @requests.delete(current_request)
      else
        current_id = (current_id + 1) % @requests.length # Modulo for looping the id from the end to the beginning of the list
      end

      if current_id >= @requests.length || # If Id's out of range (when delete a request) or
          current_request.priority > @requests[current_id].priority # THe next request is not enough prioritary, go back to the beginning
        current_id = 0
      end
    end
    @last_request_id = current_id # Save the id for the next update

    # Delete the finished requests
    @watching_requests.delete_if(&:finished?)

    # Update the watch and reload the requests
    need_sort = false
    @watching_requests.each do |request|
      request.update_watch
      next unless request.reload?
      @watching_requests.delete request
      @requests.push request
      request.on_reload
      need_sort = true
    end
    # Update the waiting requests
    @waiting_requests.each do |request|
      request.update_retry
      next unless request.reload?
      @waiting_requests.delete request
      @requests.push request
      request.on_reload
      need_sort = true
    end
    sort_requests if need_sort
  end

  # Sort the request by order of priority (highest is first)
  def self.sort_requests
    @requests.sort! { |a, b| b.priority <=> a.priority }
    @last_request_id = 0 # Reset the request id to prevent problems
  end

  #-------------------------------------------
  # Class that describe a pathfinding request
  #   A request has three caracteristics :
  #   - Character : the character summonning the request
  #   - Target : the target to reach
  #   - Priority : The priority of the request between others
  #
  # Algorithm steps
  # 1st step : Initialization
  #   Creation of the variables (#initialize)
  # 2nde step: Search
  #   Calculate NODES_PER_FRAME nodes per frame to optimize the process (#update_search)
  #   Nodes are calculated in #calculate_node with A* algorithm
  #   Once a path is found, or all possibilies are studied, the request start watching
  # 3rd step : Watch
  #   The Request look for obstacles on the path and restart the search (reload) if there is one
  class Request
    # The character which needs a path
    attr_reader :character
    # The priority of the request between others
    attr_reader :priority

    # Create the request
    # @param character [Game_Character] the character to give a path
    # @param target [Target] the target data
    # @param priority [Integer] the priority between other requests
    # @param tries [Integer, Symbol] the amount of tries allowed before fail, use :infinity to have unlimited tries
    def initialize(character, target, priority, tries)
      @character = character
      @target = target
      @priority = priority
      @state = :searching
      @cursor = Cursor.new(character)
      @open = [[character.x, character.y, character.z, 0, @cursor.get_state, -1]]
      @closed = Table32.new($game_map.width, $game_map.height, 7)
      @character.force_move_route(WAITING_ROUTE)
      @remaining_tries = @original_remaining_tries = tries
    end

    # Indicate if the request is search for path
    # @return [Boolean]
    def searching?
      return @state == :searching
    end

    # Indicate if the request is watching for obstacle
    # @return [Boolean]
    def waiting?
      return @state == :wait_retry
    end

    # Inidicate if the request is waiting for new try
    # @return [Boolean]
    def watching?
      return @state == :watching
    end

    # Indicate if the request is ended
    # @return [Boolean]
    def finished?
      return !@character.move_route_forcing
    end

    # Indicate if the request is to reload
    # @return [Boolean]
    def reload?
      return @state == :reload
    end

    # Update the request search and return the new remaining node count
    # @param node_counter [Integer] the amount of node per frame remaining
    # @return [Integer]
    def update_search(node_counter)
      # Check target already reached
      if @target.reached?(@character.x, @character.y, @character.z)
        @state = :watching
        return node_counter
      end
      # Initialize
      nodes = 0
      nodes_max = [NODES_PER_REQUEST, node_counter].min
      result = nil
      # Main loop : calculate a certain amount of node to get a result
      while nodes < nodes_max && !result
        result = calculate_node
        nodes += 1
      end
      # Handle the result
      if result == :not_found
        # If result not found, it start waiting before retrying
        if @remaining_tries == :infinity || (@remaining_tries -= 1) > 0
          @state = :wait_retry
          @retry_countdown = TRY_DELAY
        else
          # If no more chances : the path finding end here
          @state = :watching
          send_path([0])
        end
      # A path is found : throw it to the character
      elsif result
        @state = :watching
        send_path(result)
      end
      # Return the new node counter
      return (node_counter - nodes)
    end

    # Update the request when looking for obstacles
    def update_watch
      # Optimization : Detect stuckness only if the character is on one tile
      if @character.real_x % 128 + @character.real_y % 128 == 0
        if is_stucked?
          @state = :reload
        elsif @target.reached?(@character.x, @character.y, @character.z)
          @character.stop_path
        end
      end
    end

    # Update the request when waiting before retrying to find path
    def update_retry
      @retry_countdown -= 1
      @state = :reload if @retry_countdown <= 0
    end

    # Reload the request
    def on_reload
      @character.force_move_route(WAITING_ROUTE)
      @open = [[character.x, character.y, character.z, 0, @cursor.get_state, -1]]
      @closed = Table32.new($game_map.width, $game_map.height, 7)
      @state = :searching
    end

    # Make the character following the found path
    # @param path [Array<Integer>] The path, list of move direction
    def send_path(path)
      @character.force_move_route(Pathfinding.path_to_route(path))
    end

    # Detect if the character is stucked
    # @return [Boolean]
    def is_stucked?
      # Get the data
      route = @character.move_route
      route_index = @character.move_route_index
      x, y, z, b = @character.x, @character.y, @character.z, @character.__bridge

      # Iterate commands to the last one, which is Lentgh - 2 (considering the empty command at end)
      for command in route.list[route_index..[route.list.length - 2, route_index + OBSTACLE_DETECTION_RANGE - 1].min]
        return true unless @cursor.sim_move?(x, y, z, command.code, b)
        x, y, z, b = @cursor.x, @cursor.y, @cursor.z, @cursor.__bridge
      end
      return false
    end

    # Calculate a node and return it if a path is found
    # @return [Object]
    def calculate_node
      # Check for empty list
      return :not_found if (open = @open).empty?
      t1 = Time.new
      # Initialize
      target = @target
      cursor = @cursor
      character = @character
      game_map = $game_map

      # Heuristic comparaison
      # Open : [x, y, z, heuristic, state, backtrace_move]
      node = open.min do |a, b|
        next(1) if a[3] > b[3]
        next(-1) if a[3] < b[3]
        (b[0] - character.x).abs + (b[1] - character.y).abs <=> (a[0] - character.x).abs + (a[1] - character.y).abs
      end

      # Closing the selected open node
      (closed = @closed)[node[0], node[1], node[2]] = node[5]
      open.delete(node)

      # Open each side nodes
      PATH_DIRS.each do |direction|
        next unless cursor.sim_move?(node[0], node[1], node[2], direction, *node[4])
        kx, ky, kz = cursor.x, cursor.y, cursor.z
        # Check target
        if target.reached?(kx, ky, kz)
          dx, dy, dz = kx - node[0], ky - node[1], kz - node[2]
          closed[kx, ky, kz] = direction | (dx >= 0 ? 0 : 1) << 4 | dx.abs << 5 |
                               (dy >= 0 ? 0 : 1) << 9 | dy.abs << 10 |
                               (dz >= 0 ? 0 : 1) << 14 | dz.abs << 15
          return backtrace(kx, ky, kz)
        end

        # Open the node and store the backtrace
        next unless closed[kx, ky, kz] == 0 && open.select { |a| a[0] == kx && a[1] == ky && a[2] == kz }.empty?
        cost = node[3] + TAGS_WEIGHT[game_map.system_tag(kx, ky)]
        dx, dy, dz = kx - node[0], ky - node[1], kz - node[2]
        backtrace_move = direction | (dx >= 0 ? 0 : 1) << 4 | dx.abs << 5 | # Encode the backtrace data
                         (dy >= 0 ? 0 : 1) << 9 | dy.abs << 10 |
                         (dz >= 0 ? 0 : 1) << 14 | dz.abs << 15 |
                         cost << 19
        cost -= 1 if (node[5] & 0xF) == direction # Straight line are better and cost less
        open.unshift [kx, ky, kz, cost, cursor.get_state, backtrace_move] # Open the node with informations
      end
      # Target not found
      return nil
    end

    # Calculate the path from the given node
    # @param x [Object] the node
    # @return [Array<Integer>] the path
    def backtrace(tx, ty, tz)
      x, y, z = tx, ty, tz
      closed = @closed
      path = []
      code = closed[x, y, z]
      until code == -1
        path.unshift code & 0xF # Direction
        x -= ((code >> 4) & 1 > 0 ? -1 : 1) * ((code >> 5) & 0xF)
        y -= ((code >> 9) & 1 > 0 ? -1 : 1) * ((code >> 10) & 0xF)
        z -= ((code >> 14) & 1 > 0 ? -1 : 1) * ((code >> 15) & 0xF)
        code = closed[x, y, z]
      end
      # Reset the try counter
      @remaining_tries = @original_remaining_tries
      return path
    end
  end

  #-------------------------------------------
  # Class that describe and manipulate the simili character used in pathfinding
  class Cursor
    # SystemTags that trigger Surfing
    SurfTag = Game_Character::SurfTag
    # SystemTags that does not trigger leaving water
    SurfLTag = Game_Character::SurfLTag

    def x
      return @character.x
    end

    def y
      return @character.y
    end

    def z
      return @character.z
    end

    def __bridge
      return @character.__bridge
    end

    def initialize(character)
      if character == $game_player
        @character = Game_Character.new
        @character.through = character.through
        @character.character_name = character.character_name
      else
        @character = character.clone
      end
      @character.set_follower(nil)
      @character.can_make_footprint = false
      @character.particles_disabled = true
    end

    def get_state
      return [@character.__bridge, @character.sliding, @character.surfing?]
    end

    # Simulate the mouvement of the character and store the data into cursor's attributes
    # @param x [Integer] start coords X
    # @param y [Integer] start coords Y
    # @param z [Integer] start coords z
    # @param code [Integer] mouvement's code
    # @return [Boolean]
    def sim_move?(sx, sy, sz, code, b = @character.__bridge, slide = @character.sliding?, surf = @character.surfing?)
      (char = @character).moveto(sx, sy)
      char.z = sz
      char.__bridge = b
      char.sliding = slide
      char.surfing = surf

      case code
      when 1
        char.move_down
      when 2
        char.move_left
      when 3
        char.move_right
      when 4
        char.move_up
      end
      return (char.x != sx || char.y != sy)
    end
  end

  # Class that describe the pathfinding targets. 
  # There is different type of targets :
  # - Coords : reach a specific point in the map, can have a radius
  # - Character : reach a game character object in the map, can have a radius
  # Each target can be tested by the reached? method
  module Target
    # Convert the raw data to a target object with #reached?(x,y,z) method
    # @param data [Array] data to convert
    # @return [Object]
    def self.get(data)
      if data[0].is_a?(Game_Character)
        return Target::Character.new(data[0], data[1])
      else
        return Target::Coords.new(data[0][0], data[0][1], data[0][2], data[1])
      end
    end

    class Coords
      attr_reader :x, :y, :z
      def initialize(x, y, z, radius)
        @x, @y, @z, @radius = x + Yuki::MapLinker.get_OffsetX, y + Yuki::MapLinker.get_OffsetY, z, radius
      end

      def reached?(x, y, z)
        return ((@x - x).abs + (@y - y).abs) <= @radius
      end
    end

    class Character
      def x
        return @character.x
      end

      def y
        return @character.y
      end

      def z
        return @character.z
      end

      def initialize(character, radius=1)
        @character = character
        @radius = radius
      end

      def reached?(x, y, z)
        return ((@character.x - x).abs + (@character.y - y).abs) <= @radius
      end
    end
  end
end
