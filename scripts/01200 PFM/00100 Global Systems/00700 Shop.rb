module PFM
  class Shop
    # Array
    # @return [Hash]
    attr_accessor :shop_list

    def initialize
    @shop_list = {}
    @pokemon_shop_list = {}
    end

    # Create a new limited Shop
    # @param symbol_of_new_shop [Symbol] the symbol to link to the new shop
    # @param list_of_item_id [Array<Integer>] the array containing the id of the items to sell
    # @param list_of_item_quantity [Array<Integer>] the array containing the quantity of the items to sell
    # @param shop_rewrite [Boolean] if the system must completely overwrite an already existing shop
    def create_new_limited_shop(symbol_of_new_shop, list_of_item_id = [], list_of_item_quantity = [], shop_rewrite: false)
      return unless shop_param_legit?(symbol_of_new_shop, list_of_item_id, list_of_item_quantity)

      if @shop_list.key?(symbol_of_new_shop) && shop_rewrite
        @shop_list.delete(symbol_of_new_shop)
      elsif @shop_list.key?(symbol_of_new_shop) && shop_rewrite == false
        return refill_limited_shop(symbol_of_new_shop, list_of_item_id, list_of_item_quantity)

      end
      @shop_list[symbol_of_new_shop] = {}
      list_of_item_id.each_with_index do |id, index|
        if GameData::Item.limited_use?(id)
          @shop_list[symbol_of_new_shop][id] = (list_of_item_quantity[index] != nil ? list_of_item_quantity[index] : 1)
        else
          @shop_list[symbol_of_new_shop][id] = 1
        end
      end
    end

    # Refill an already existing shop with items (Create the shop if it does not exist)
    # @param symbol_of_shop [Symbol] the symbol of the existing shop
    # @param list_item_id_to_refill [Array<Integer>] the array of the items' id
    # @param list_quantity_to_refill [Array<Integer>] the array of the quantity to refill
    def refill_limited_shop(symbol_of_shop, list_item_id_to_refill = [], list_quantity_to_refill = [])
      return unless shop_param_legit?(symbol_of_shop, list_item_id_to_refill, list_quantity_to_refill)

      if @shop_list.key?(symbol_of_shop)
        list_item_id_to_refill.each_with_index do |id, index|
          @shop_list[symbol_of_shop][id] = 0 if !@shop_list[symbol_of_shop].key?(id)
          if GameData::Item.limited_use?(id)
            @shop_list[symbol_of_shop][id] += (list_quantity_to_refill[index] != nil ? list_quantity_to_refill[index] : 1)
          else
            @shop_list[symbol_of_shop][id] = 1
          end
        end
      else 
        create_new_limited_shop(symbol_of_shop, list_item_id_to_refill, list_quantity_to_refill) # We create a shop if one do not already exist
      end
    end

    # Remove items from an already existing shop (return if do not exist)
    # @param symbol_of_shop [Symbol] the symbol of the existing shop
    # @param list_item_id_to_remove [Array<Integer>] the array of the items' id
    # @param list_quantity_to_remove [Array<Integer>] the array of the quantity to remove
    def remove_from_limited_shop(symbol_of_shop, list_item_id_to_remove, list_quantity_to_remove)
      return unless shop_param_legit?(symbol_of_shop, list_item_id_to_remove, list_quantity_to_remove)
      return if !@shop_list.key?(symbol_of_shop)

      list_item_id_to_remove.each_with_index do |id, index|
        next if !@shop_list[symbol_of_shop].key?(id)

        @shop_list[symbol_of_shop][id] -= (list_quantity_to_remove[index] != nil ? list_quantity_to_remove[index] : 999)
        @shop_list[symbol_of_shop].delete(id) if @shop_list[symbol_of_shop][id] <= 0
      end
    end

    # Check the legitimity of the parameters
    # @param symbol_of_shop [Symbol]
    # @param list_item_id_to_remove [Array<Integer>]
    # @param list_quantity_to_remove [Array<Integer>]
    # @return [Boolean] return true if all params are legit
    def shop_param_legit?(symbol, arr1, arr2)
      validate_param(:shop_param_legit?, :symbol, symbol => Symbol)
      validate_param(:shop_param_legit?, :arr1, arr1 => { Array => Integer })
      validate_param(:shop_param_legit?, :arr2, arr2 => { Array => Integer })
      return true
    end
  end

  class Pokemon_Party
    # The list of the limited shops
    # @return [PFM::Shop]
    attr_accessor :shop
    on_player_initialize(:shop) { @shop = PFM::Shop.new }
    on_expand_global_variables(:shop) {
      # Variable containing the limited shops information
      @shop ||= PFM::Shop.new
    }
  end
end
