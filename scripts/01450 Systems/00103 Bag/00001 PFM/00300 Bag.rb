module PFM
  # InGame Bag management
  #
  # The global Bag object is stored in $bag and PFM.game_state.bag
  # @author Nuri Yuri
  class Bag
    # Last socket used in the bag
    # @return [Integer]
    attr_accessor :last_socket
    # Last index in the socket
    # @return [Integer]
    attr_accessor :last_index
    # If the bag is locked (and react as being empty)
    # @return [Boolean]
    attr_accessor :locked
    # Set the last battle item
    # @return [Symbol]
    attr_accessor :last_battle_item_db_symbol
    # Set the last ball used
    # @return [Symbol]
    attr_accessor :last_ball_used_db_symbol
    # Tell if the bag is alpha sorted
    # @return [Boolean]
    attr_accessor :alpha_sorted
    # Get the game state responsive of the whole game state
    # @return [PFM::GameState]
    attr_accessor :game_state

    # Number of shortcut
    SHORTCUT_AMOUNT = 4
    # Create a new Bag
    # @param game_state [PFM::GameState] variable responsive of containing the whole game state for easier access
    def initialize(game_state = PFM.game_state)
      self.game_state = game_state
      # @type [Hash<Symbol => Integer>]
      @items = Hash.new(0)
      @orders = [[], [], [], [], [], [], []]
      @last_socket = 1
      @last_index = 0
      @shortcut = Array.new(SHORTCUT_AMOUNT, :__undef__)
      @locked = false
      @last_battle_item_db_symbol = :__undef__
      @last_ball_used_db_symbol = :__undef__
      @alpha_sorted = false
    end

    # Convert bag to .26 format
    def convert_to_dot26
      return if @items.is_a?(Hash)

      items = Hash.new(0)
      items.merge!(
        @items.map.with_index { |quantity, id| [data_item(id).db_symbol, quantity] }.reject { |v| v.last == 0 }.to_h
      )
      items.delete(:__undef__)
      @items = items
      @orders.map! { |order| order.map { |id| data_item(id).db_symbol }.reject { |db_symbol| db_symbol == :__undef__ } }
    ensure
      @items.transform_values! { |v| v || 0 }
    end

    # If the bag contain a specific item
    # @param db_symbol [Symbol] db_symbol of the item
    # @return [Boolean]
    def contain_item?(db_symbol)
      return item_quantity(db_symbol) > 0
    end
    alias has_item? contain_item?

    # Tell if the bag is empty
    # @return [Boolean]
    def empty?
      return @items.empty?
    end

    # The quantity of an item in the bag
    # @param db_symbol [Symbol] db_symbol of the item
    # @return [Integer]
    def item_quantity(db_symbol)
      return 0 if @locked

      db_symbol = data_item(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return @items[db_symbol]
    end

    # Add items in the bag and trigger the right quest objective
    # @param db_symbol [Symbol] db_symbol of the item
    # @param nb [Integer] number of item to add
    def add_item(db_symbol, nb = 1)
      return if @locked
      return remove_item(db_symbol, -nb) if nb < 0

      db_symbol = data_item(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      @items[db_symbol] += nb
      add_item_to_order(db_symbol)
      game_state.quests.add_item(db_symbol) unless game_state.bag != self
    end
    alias store_item add_item

    # Remove items from the bag
    # @param db_symbol [Symbol] db_symbol of the item
    # @param nb [Integer] number of item to remove
    def remove_item(db_symbol, nb = 999)
      return if @locked
      return add_item(db_symbol, -nb) if nb < 0

      db_symbol = data_item(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      @items[db_symbol] -= nb
      if @items[db_symbol] <= 0
        @items.delete(db_symbol)
        remove_item_from_order(db_symbol)
      end
    end
    alias drop_item remove_item

    # Get the order of items in a socket
    # @param socket [Integer, Symbol] ID of the socket
    # @return [Array]
    def get_order(socket)
      return [] if @locked
      return @shortcut if socket == :favorites
      return process_battle_order(socket) if socket.is_a?(Symbol) # TODO

      return (@orders[socket] ||= [])
    end

    # Reset the order of items in a socket
    # @param socket [Integer] ID of the socket
    # @return [Array] the new order
    def reset_order(socket)
      arr = get_order(socket)
      arr.select! { |db_symbol| data_item(db_symbol).socket == socket && @items[db_symbol] > 0 } unless socket == :favorites
      unless each_data_item.select { |item| item.socket == socket }.all? { |item| item.position.zero? }
        arr.sort! { |a, b| data_item(a).position <=> data_item(b).position }
      end
      @alpha_sorted = false
      return arr
    end
    alias sort_ids reset_order

    # Sort the item of a socket by their names
    # @param socket [Integer] ID of the socket
    # @param reverse [Boolean] if we want to sort reverse
    def sort_alpha(socket, reverse = false)
      if reverse
        reset_order(socket).sort! { |a, b| data_item(b).name <=> data_item(a).name }
        @alpha_sorted = false
      else
        reset_order(socket).sort! { |a, b| data_item(a).name <=> data_item(b).name }
        @alpha_sorted = true
      end
    end

    # Get the shortcuts
    # @return [Array<Symbol>]
    def shortcuts
      @shortcut ||= Array.new(SHORTCUT_AMOUNT, :__undef__)
      return @shortcut
    end
    alias get_shortcuts shortcuts

    # Get the last battle item
    # @return [Studio::Item]
    def last_battle_item
      data_item(@last_battle_item_db_symbol)
    end

    private

    # Make sure the item is in the order, if not add it
    # @param db_symbol [Symbol] db_symbol of the item
    def add_item_to_order(db_symbol)
      return if @items[db_symbol] <= 0

      socket = data_item(db_symbol).socket
      get_order(socket) << db_symbol unless get_order(socket).include?(db_symbol)
    end

    # Make sure the item is not in the order anymore
    # @param db_symbol [Symbol] db_symbol of the item
    def remove_item_from_order(db_symbol)
      return unless @items[db_symbol] <= 0

      get_order(data_item(db_symbol).socket).delete(db_symbol)
    end
  end

  class GameState
    # The bag of the player
    # @return [PFM::Bag]
    attr_accessor :bag

    on_initialize(:bag) { @bag = PFM.bag_class.new(self) }
    on_expand_global_variables(:bag) do
      # Variable containing the player's bag information
      $bag = @bag
      $bag.game_state = self
      $bag.convert_to_dot26 if trainer.current_version < 6659
    end
  end
end

PFM.bag_class = PFM::Bag
