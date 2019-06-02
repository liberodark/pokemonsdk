# Pathfinding (PSDK) by Leikt
# Module that handle the automatic pathfinding system.
# Djikstra Algorithm and optimized to be performance friendly.
# If you are experimenting performance issue while the algorithm is running, down the NODE_PER_FRAME value.
# You can customize the cost of each tag in TAGS_WEIGHT.

module Pathfinding
  # Amount of node to calculate in one frame (OPTIMISATION)
  OPERATION_PER_FRAME = 150
  # Amount of node by requests in one frame (OPTIMISATION)
  OPERATION_PER_REQUEST = 50
  # Cost of the reload
  COST_RELOAD = 15
  # Cost of the watch
  COST_WATCH = 9
  # Cost of the wait
  COST_WAIT = 1

  # Obstacle detection range
  OBSTACLE_DETECTION_RANGE = 9
  # Amount of try count
  TRY_COUNT = 5
  # Number of frame before two path search when the first one fail
  TRY_DELAY = 60

  # Directions to check
  PATH_DIRS = [1, 2, 3, 4]
  # Move route when waiting for a new path
  WAITING_ROUTE = RPG::MoveRoute.new
  WAITING_ROUTE.list.unshift(RPG::MoveCommand.new(15, 1))

  # Weight of the tags, the higher is the cost, the more the path will avoid it
  TAGS_WEIGHT = {
    GameData::SystemTags::Road => 2,          # Tag of the main road
    GameData::SystemTags::SwampBorder => 20,  # Avoid swamp if possible
    GameData::SystemTags::DeepSwamp => 30,    # Avoid deep swamp whatever it takes
    GameData::SystemTags::MachBike => 1000,   # Prevent bug
    GameData::SystemTags::TGrass => 20
  }
  TAGS_WEIGHT.default = 10 # Grass, ...

  # Default save state
  DEFAULT_SAVE = []

  # Initialisation
  # List of requests looking for a path
  @requests = []
  # Amount of operation per frame
  @operation_per_frame = OPERATION_PER_FRAME
  # Last updated researching request
  @last_request_id = 0

  PRESET_COMMANDS = Array.new(5) { |i| RPG::MoveCommand.new(i) }.method(:[])
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
  # @param tries [Integer] the number of tries before giving up the path research. :infinity for infinite try count.
  # @return [Boolean] if the request is successfully submitted
  def self.add_request(character, target, tries)
    remove_request(character)
    @requests.push Request.new(character, Target.get(*target), tries)
    return true
  end

  # Remove the request from the system list and return true if the request has been popped out.
  # @param character [Game_Character] the character to pop out
  # @return [Boolean] if the request has been popped out
  def self.remove_request(character)
    old_length = @requests.length
    @requests.delete_if { |e| e.character == character }
    @last_request_id = 0 # Reset the request id to prevent problems
    return (old_length > @requests.length)
  end

  # CLear all the requests
  def self.clear
    @requests.clone.each { |request| remove_request(request.character) }
  end

  # Set the number of operation per frame. By default it's 150, be careful with the performance issues.
  # @param value [Integer] the new amount of operation allowed per frame
  def self.operation_per_frame=(value)
    @operation_per_frame = value
  end

  # Update the pathfinding system
  def self.update
    return if @requests.empty?
    
    # Initialize
    request_id = @last_request_id # Get the last updates where it's stop
    operation_counter = 0         # Count the amount of operation in this update
    first_update = true           # Indicate if the update is called in the first loop or not
    need_update = true            # When go false for a all loop => stop update
    # Loop while remains operation left and requests
    while operation_counter < @operation_per_frame
      # Update the request and calculate the new operation counter
      operation_counter += (current_request = @requests[request_id]).update(operation_counter, first_update)
      need_update ||= current_request.need_update # Need update to true if the request needs update and keep its value if not
      current_request.character.stop_path if current_request.finished? # Delete the finished requests

      # When end of the requests list
      next unless (request_id += 1) >= @requests.length

      request_id = 0 # Go to the first request
      break if !need_update or @requests.empty? # Stop everything if update no longer needed

      first_update = false      # At this point it can't be the first update
      need_update = false       # No first update, reset the need_update to false, it will be turned to true if update is needed
    end
    @last_request_id = request_id # Save the last update position
  end

  # Create an savable array of the current requests
  # @return [Array<Pathfinding::Request>]
  def self.save
    $pokemon_party.pathfinding_requests = @requests.collect(&:save)
  end

  # Load the data from the pokemon_party
  def self.load
    return unless Game_Map::PATH_FINDING_ENABLED
    data = $pokemon_party.pathfinding_requests
    @requests = data.collect { |d| Request.load(d)}
    @requests.delete(nil) # Prevent loading error
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
    # @return [Game_Character]
    attr_reader :character
    # Indicate if the request needs update or not
    # @return [Boolean]
    attr_reader :need_update

    # Create the request
    # @param character [Game_Character] the character to give a path
    # @param target [Target] the target data
    # @param tries [Integer, Symbol] the amount of tries allowed before fail, use :infinity to have unlimited tries
    def initialize(character, target, tries)
      @character = character
      @target = target
      @state = :search
      @cursor = Cursor.new(character)
      @open = [[0, character.x, character.y, character.z, @cursor.state, -1]]
      @closed = Table32.new($game_map.width, $game_map.height, 7)
      @character.force_move_route(WAITING_ROUTE)
      @remaining_tries = @original_remaining_tries = tries
      @need_update = true
    end

    # Indicate if the request is search for path
    # @return [Boolean]
    def searching?
      return @state == :search
    end

    # Indicate if the request is watching for obstacle
    # @return [Boolean]
    def waiting?
      return @state == :wait
    end

    # Inidicate if the request is waiting for new try
    # @return [Boolean]
    def watching?
      return @state == :watch
    end

    # Indicate if the request is to reload
    # @return [Boolean]
    def reload?
      return @state == :reload
    end

    # Indicate if the request is ended
    # @return [Boolean]
    def finished?
      return !@character.move_route_forcing
    end

    def show
      pc [@state].inspect
    end

    # Update the requests and return the number of performed actions
    # @param operation_counter [Integer] the amount of operation left
    # @param is_first_update [Boolean] indicate if it's the first update of the frame
    # @return [Integer]
    def update(operation_counter, is_first_update)
      @need_update ||= is_first_update # Need update forced to true if it's the first update
      case @state
      when :search then return update_search(operation_counter)
      when :watch then return update_watch(is_first_update)
      when :reload then return update_reload(is_first_update)
      when :wait then return update_wait(is_first_update)
      else
        return 1
      end
    end

    # Update the request search and return the new remaining node count
    # @param node_counter [Integer] the amount of node per frame remaining
    # @return [Integer]
    def update_search(operation_counter)
      # Check target already reached
      if @target.reached?(@character.x, @character.y, @character.z)
        @state = :watch
        return 1
      elsif @target.check_move(@character.x, @character.y)
        @state = :reload
        return 1
      end
      # Initialize
      nodes = 0
      nodes_max = operation_counter > OPERATION_PER_REQUEST ? OPERATION_PER_REQUEST : operation_counter
      result = nil
      # Main loop : calculate a certain amount of node to get a result
      while nodes < nodes_max && !result
        result = calculate_node
        nodes += 1
      end
      # Process the result
      process_result(result)
      return nodes + 1
    end

    # Process the result of the node calculation
    # @param result [Array<Integer>, nil, Symbol] the result value
    def process_result(result)
      if result == :not_found
        # If result not found, it start waiting before retrying
        if @remaining_tries == :infinity || (@remaining_tries -= 1) > 0
          @state = :wait
          @retry_countdown = TRY_DELAY
        else
          # If no more chances : the path finding end here
          @character.stop_path
        end
      # A path is found : throw it to the character
      elsif result
        # Reset the try counter
        @remaining_tries = @original_remaining_tries
        # Start watching for obstacles
        @state = :watch
        send_path(result)
      end
    end

    # Update the request when looking for obstacles
    def update_watch(is_first_update)
      # Check first update
      return 1 unless is_first_update

      # Check target movement
      if @target.check_move(@character.x, @character.y)
        @state = :reload
        return 1
      end
      # Optimization : Detect stuckness only if the character is on one tile
      if @character.real_x % 128 + @character.real_y % 128 == 0
        if stucked?
          @state = :reload
        # Detect if the target is already reached (player passing next to the event, etc)
        elsif @target.reached?(@character.x, @character.y, @character.z)
          @character.stop_path
        end
      end
      # Return default cost of a watch update
      @need_update = false
      return COST_WATCH
    end

    # Update the request when waiting before retrying to find path
    def update_wait(is_first_update)
      # Check first update
      return 1 unless is_first_update

      # Update the count_down
      @retry_countdown -= 1
      @state = :reload if @retry_countdown <= 0
      @need_update = false
      return COST_WAIT
    end

    # Reload the request
    def update_reload(is_first_update)
      # Check first update
      return 1 unless is_first_update

      @character.force_move_route(WAITING_ROUTE)
      @open.clear
      @open.push [0, character.x, character.y, character.z, @cursor.state, -1]
      @closed.resize(0, 0, 0) # Clear the table
      @closed.resize($game_map.width, $game_map.height, 7)
      @state = :search
      return COST_RELOAD
    end

    # Make the character following the found path
    # @param path [Array<Integer>] The path, list of move direction
    def send_path(path)
      @character.force_move_route(Pathfinding.path_to_route(path))
    end

    # Detect if the character is stucked
    # @return [Boolean]
    def stucked?
      # Get the data
      route = @character.move_route
      route_index = @character.move_route_index
      x = @character.x
      y = @character.y
      z = @character.z
      b = @character.__bridge

      # Iterate commands to the last one, which is Lentgh - 2 (considering the empty command at end)
      route.list[route_index..[route.list.length - 2, route_index + OBSTACLE_DETECTION_RANGE - 1].min]&.each do |command|
        return true unless @cursor.sim_move?(x, y, z, command.code, b)

        x = @cursor.x
        y = @cursor.y
        z = @cursor.z
        b = @cursor.__bridge
      end
      return false
    end

    # Calculate a node and return it if a path is found
    # @return [Object]
    def calculate_node
      # Check for empty list
      return :not_found if (open = @open).empty?

      # Initialize
      target = @target
      cursor = @cursor
      game_map = $game_map

      # Get next node
      node = open.shift

      # Closing the selected open node
      (closed = @closed)[node[1], node[2], node[3]] = node[5]

      # Open each side nodes
      PATH_DIRS.each do |direction|
        next unless cursor.sim_move?(node[1], node[2], node[3], direction, *node[4])

        # Check target
        if target.reached?(kx = cursor.x, ky = cursor.y, kz = cursor.z)
          closed[kx, ky, kz] = direction | node[1] << 4 | node[2] << 14 | node[3] << 24
          return backtrace(kx, ky, kz)
        end

        # Open the node and store the backtrace
        next unless closed[kx, ky, kz] == 0 && open.select { |a| a[1] == kx && a[2] == ky && a[3] == kz }.empty?

        # Cost calculation : start with last node cost
        # Add the weight of the tag
        # Retreive the straight direction (we prefer straight lines)
        cost = node.first + TAGS_WEIGHT[game_map.system_tag(kx, ky)] - ((node[5] & 0xF) == direction ? 1 : 0)
        backtrace_move = direction | node[1] << 4 | node[2] << 14 | node[3] << 24
        # Sort and insert the new node
        unless open.empty?
            index = 0
            index += 1 while index < open.length and open[index].first < cost
            open.insert(index, [cost, kx, ky, kz, cursor.state, backtrace_move])
        else
            open[0] = [cost, kx, ky, kz, cursor.state, backtrace_move]
        end
      end
      # Target not found
      return nil
    end

    # Calculate the path from the given node
    # @param x [Object] the node
    # @return [Array<Integer>] the path
    def backtrace(tx, ty, tz)
      x = tx
      y = ty
      z = tz
      closed = @closed
      path = []
      code = closed[x, y, z]
      until code == -1
        path.unshift code & 0xF # Direction
        x = (code >> 4) & 0x3FF
        y = (code >> 14) & 0x3FF
        z = (code >> 24) & 0xF
        code = closed[x, y, z]
      end
      return path
    end

    # Gather the data ready to be saved
    # @return [Array<Object>]
    def save
      return [@character.id, @target.save, @original_remaining_tries]
    end

    # (Class method) Load the requests from the given argument
    # @param data [Array<Object>] the data generated by the save method
    def self.load(data)
      character = $game_map.events[data[0]]
      target    = Target.load(data[1])
      tries     = data[2]
      return nil unless character && target && tries # Prevent loading error : when map change
      return Request.new(character, target, tries)
    end
  end
end