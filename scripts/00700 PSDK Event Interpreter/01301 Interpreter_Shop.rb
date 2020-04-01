class Interpreter
  # Open a shop
  # @overload open_shop(items, prices)
  #   @param items [Symbol]
  #   @param prices [Hash] (optional)
  # @overload open_shop(items,prices)
  #   @param items [Array<Integer>]
  #   @param prices [Hash] (optional)
  def open_shop(items, prices = nil, show_background: true)
    if prices
      GamePlay::Shop.new(items, prices, show_background: show_background).main
    else
      GamePlay::Shop.new(items, show_background: show_background).main
    end
    Graphics.transition
    @wait_count = 2
  end
  alias ouvrir_magasin open_shop 

  # Create a limited shop (in the main PFM::Shop object)
  def add_limited_shop(symbol_of_new_shop, list_of_item_id = [], list_of_item_quantity = [], shop_rewrite: false)
    $pokemon_party.shop.create_new_limited_shop(symbol_of_new_shop, list_of_item_id, list_of_item_quantity, shop_rewrite: shop_rewrite)
  end
  alias ajouter_un_magasin_limite add_limited_shop

  # Add items to a limited shop
  def add_items_to_limited_shop(symbol_of_shop, list_item_id_to_refill = [], list_quantity_to_refill = [])
    $pokemon_party.shop.refill_limited_shop(symbol_of_shop, list_item_id_to_refill, list_quantity_to_refill)
  end
  alias ajouter_objets_magasin add_items_to_limited_shop

  # Remove items from a limited shop
  def remove_items_from_limited_shop(symbol_of_shop, list_item_id_to_remove, list_quantity_to_remove)
    $pokemon_party.shop.remove_from_limited_shop(symbol_of_shop, list_item_id_to_remove, list_quantity_to_remove)
  end
  alias enlever_objets_magasin remove_items_from_limited_shop

  # Open a Pokemon shop
  def pokemon_shop_open(symbol_or_list, param = [], prices = {})
    # GamePlay::Pokemon_Shop.new(symbol_or_list, param, prices).main
    # Graphics.transition
    # @wait_count = 2
    show_message(:pokemon_shop_unavailable, header: SYSTEM_MESSAGE_HEADER)
  end
  alias ouvrir_magasin_pokemon pokemon_shop_open
end
