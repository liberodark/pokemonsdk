module PFM
  # Class describing the shop logic
  class Shop
    # Hash containing the defined shops
    # @return [Hash{Symbol => Hash{Symbol => Integer}}]
    attr_accessor :shop_list
    # Hash containing the defined Pokemon shops
    # @return [Hash{Symbol => Array}]
    attr_accessor :pokemon_shop_list
    # Get the game state responsive of the whole game state
    # @return [PFM::GameState]
    attr_accessor :game_state

    # Create a new shop handler
    # @param game_state [PFM::GameState] variable responsive of containing the whole game state for easier access
    def initialize(game_state = PFM.game_state)
      @shop_list = {}
      @pokemon_shop_list = {}
      @game_state = game_state
    end

    # Create a new limited Shop
    # @param symbol_of_shop [Symbol] the symbol to link to the new shop
    # @param items_sym [Array<Symbol, Integer>] the array containing the symbols/id of the items to sell
    # @param items_quantity [Array<Integer>] the array containing the quantity of the items to sell
    # @param shop_rewrite [Boolean] if the system must completely overwrite an already existing shop
    def create_new_limited_shop(symbol_of_shop, items_sym = [], items_quantity = [], shop_rewrite: false)
      return refill_limited_shop(symbol_of_shop, items_sym, items_quantity) if @shop_list.key?(symbol_of_shop) && !shop_rewrite

      @shop_list.delete(symbol_of_shop) if @shop_list.key?(symbol_of_shop) && shop_rewrite
      @shop_list[symbol_of_shop] = {}
      refill_limited_shop(symbol_of_shop, items_sym, items_quantity)
    end

    # Refill an already existing shop with items (Create the shop if it does not exist)
    # @param symbol_of_shop [Symbol] the symbol of the existing shop
    # @param items_to_refill [Array<Symbol, Integer>] the array of the items' db_symbol/id
    # @param quantities_to_refill [Array<Integer>] the array of the quantity to refill
    def refill_limited_shop(symbol_of_shop, items_to_refill = [], quantities_to_refill = [])
      if @shop_list.key?(symbol_of_shop)
        items_to_refill.each_with_index do |id, index|
          key = @shop_list[symbol_of_shop].keys.index { |hash_key| data_item(hash_key).db_symbol == data_item(id).db_symbol }
          id = data_item(id).db_symbol
          @shop_list[symbol_of_shop][id] = 0 unless key
          @shop_list[symbol_of_shop][id] += quantities_to_refill[index] || 1
          @shop_list[symbol_of_shop][id] = 1 unless data_item(id).is_limited
        end
      else # We create a shop if one do not already exist
        create_new_limited_shop(symbol_of_shop, items_to_refill, quantities_to_refill)
      end
    end

    # Remove items from an already existing shop (return if do not exist)
    # @param symbol_of_shop [Symbol] the symbol of the existing shop
    # @param items_to_remove [Array<Symbol, Integer>] the array of the items' db_symbol/id
    # @param quantities_to_remove [Array<Integer>] the array of the quantity to remove
    def remove_from_limited_shop(symbol_of_shop, items_to_remove, quantities_to_remove)
      return log_debug("You can't remove items from a non-existing shop") unless @shop_list.key?(symbol_of_shop)

      items_to_remove.each_with_index do |id, index|
        key = @shop_list[symbol_of_shop].keys.index { |hash_key| data_item(hash_key).db_symbol == data_item(id).db_symbol }
        id = data_item(id).db_symbol
        next unless key

        @shop_list[symbol_of_shop][id] -= (quantities_to_remove[index].nil? ? Float::INFINITY : quantities_to_remove[index])
        @shop_list[symbol_of_shop].delete(id) if @shop_list[symbol_of_shop][id] <= 0
      end
    end

    # Create a new Pokemon Shop
    # @param sym_new_shop [Symbol] the symbol to link to the new shop
    # @param list_id [Array<Integer>] the array containing the id of the Pokemon to sell
    # @param list_price [Array<Integer>] the array containing the prices of the Pokemon to sell
    # @param list_param [Array] the array containing the infos of the Pokemon to sell
    # @param list_quantity [Array<Integer>] the array containing the quantity of the Pokemon to sell
    # @param shop_rewrite [Boolean] if the system must completely overwrite an already existing shop
    def create_new_pokemon_shop(sym_new_shop, list_id, list_price, list_param, list_quantity = [], shop_rewrite: false)
      return refill_pokemon_shop(sym_new_shop, list_id, list_price, list_param, list_quantity) if @pokemon_shop_list.key?(sym_new_shop) && !shop_rewrite

      @pokemon_shop_list.delete(sym_new_shop) if @pokemon_shop_list.key?(sym_new_shop) && shop_rewrite
      @pokemon_shop_list[sym_new_shop] = []
      refill_pokemon_shop(sym_new_shop, list_id, list_price, list_param, list_quantity)
    end

    # Refill an already existing Pokemon Shop (create it if it does not exist)
    # @param symbol_of_shop [Symbol] the symbol of the shop
    # @param list_id [Array<Integer>] the array containing the id of the Pokemon to sell
    # @param list_price [Array<Integer>] the array containing the prices of the Pokemon to sell
    # @param list_param [Array] the array containing the infos of the Pokemon to sell
    # @param list_quantity [Array<Integer>] the array containing the quantity of the Pokemon to sell
    # @param pkm_rewrite [Boolean] if the system must completely overwrite the existing Pokemon
    def refill_pokemon_shop(symbol_of_shop, list_id, list_price = [], list_param = [], list_quantity = [], pkm_rewrite: false)
      if @pokemon_shop_list.key?(symbol_of_shop)
        list_id.each_with_index do |id, index|
          register_new_pokemon_in_shop(symbol_of_shop, id, list_price[index], list_param[index],
                                       list_quantity[index], rewrite: pkm_rewrite)
        end
        sort_pokemon_shop(symbol_of_shop)
      else # We create a shop if one do not already exist
        create_new_pokemon_shop(symbol_of_shop, list_id, list_price, list_param, list_quantity)
      end
    end

    # Remove Pokemon from an already existing shop (return if do not exist)
    # @param symbol_of_shop [Symbol] the symbol of the existing shop
    # @param remove_list_mon [Array<Integer>] the array of the Pokemon id
    # @param param_form [Array<Hash>] the form of the Pokemon to delete (only if there is more than one form of a Pokemon in the list)
    # @param quantities_to_remove [Array<Integer>] the array of the quantity to remove
    def remove_from_pokemon_shop(symbol_of_shop, remove_list_mon, param_form = [], quantities_to_remove = [])
      return log_debug("You can't remove Pokemon from a non-existing shop") unless @pokemon_shop_list.key?(symbol_of_shop)

      pkm_list = @pokemon_shop_list[symbol_of_shop]
      remove_list_mon.each_with_index do |id, index|
        form = param_form[index].is_a?(Hash) ? param_form[index][:form].to_i : 0

        result = pkm_list.find_index { |hash| data_creature(hash[:id]).db_symbol == data_creature(id).db_symbol && hash[:form].to_i == form }
        next unless result

        pkm_list[result][:quantity] -= (quantities_to_remove[index].nil? ? Float::INFINITY : quantities_to_remove[index])
        pkm_list.delete_at(result) if pkm_list[result][:quantity] <= 0
      end
      @pokemon_shop_list[symbol_of_shop] = pkm_list
      sort_pokemon_shop(symbol_of_shop)
    end

    # Register the Pokemon into the Array under certain conditions
    # @param sym_shop [Symbol] the symbol of the shop
    # @param id [Integer] the ID of the Pokemon to register
    # @param price [Integer] the price of the Pokemon
    # @param param [Hash] the hash of the Pokemon (might be a single Integer)
    # @param quantity [Integer] the quantity of the Pokemon to register
    # @param rewrite [Boolean] if an existing Pokemon should be rewritten or not
    def register_new_pokemon_in_shop(sym_shop, id, price, param, quantity, rewrite: false)
      return unless price && param

      param = { level: param } if param.is_a?(Integer)
      index_condition = proc { |hash| data_creature(hash[:id]).db_symbol == data_creature(id).db_symbol && hash[:form].to_i == param[:form].to_i }

      if (result = @pokemon_shop_list[sym_shop].index(&index_condition)) && rewrite
        @pokemon_shop_list[sym_shop].delete_at(result)
      elsif (result = @pokemon_shop_list[sym_shop].index(&index_condition))
        return @pokemon_shop_list[sym_shop][result][:quantity] += quantity || 1
      end

      hash_pkm = param.dup
      hash_pkm[:id] = data_creature(id).db_symbol
      hash_pkm[:price] = price
      hash_pkm[:quantity] = quantity || 1

      @pokemon_shop_list[sym_shop] << hash_pkm
    end

    # Sort the Pokemon Shop list
    # @param symbol_of_shop [Symbol] the symbol of the shop to sort
    def sort_pokemon_shop(symbol_of_shop)
      @pokemon_shop_list[symbol_of_shop].sort_by! { |hash| [data_creature(hash[:id]).id, hash[:form].to_i] }
    end

    # Ensure every ids stocked for every available shop is converted to a db_symbol
    def migrate_ids_to_symbols
      shop_list.each do |sym_shop, shop|
        new_shop = shop.dup
        shop.each_key do |key|
          next if key.is_a?(Symbol)

          new_shop[data_item(key).db_symbol] = new_shop.delete key
        end
        shop_list[sym_shop] = new_shop
      end
      pokemon_shop_list.each do |_sym_shop, shop|
        shop.each do |pokemon_hash|
          next if pokemon_hash[:id].is_a? Symbol

          pokemon_hash[:id] = data_creature(pokemon_hash.delete(:id)).db_symbol
        end
      end
    end
  end

  class GameState
    # The list of the limited shops
    # @return [PFM::Shop]
    attr_accessor :shop

    on_player_initialize(:shop) { @shop = PFM.shop_class.new(self) }
    on_expand_global_variables(:shop) do
      # Variable containing the limited shops information
      @shop ||= PFM.shop_class.new(self)
      # Migration of old saves
      @shop.pokemon_shop_list ||= {}
      @shop.game_state = self
      # We convert all the IDs to db_symbols in the already created shops
      @shop.migrate_ids_to_symbols if trainer.current_version < 6677
    end
  end
end

PFM.shop_class = PFM::Shop
