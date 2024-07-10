class Interpreter
  # Open a shop
  # @overload open_shop(items, prices)
  #   @param symbol_or_list [Symbol]
  #   @param prices [Hash] (optional)
  # @overload open_shop(items,prices)
  #   @param symbol_or_list [Array<Integer, Symbol>]
  #   @param prices [Hash] (optional)
  def open_shop(symbol_or_list, prices = {}, show_background: true)
    $scene.call_scene(GamePlay::Shop, symbol_or_list, prices, show_background: show_background)
    @wait_count = 2
  end
  alias ouvrir_magasin open_shop

  # Create a limited shop (in the main PFM::Shop object)
  # @param symbol_of_shop [Symbol] the symbol to link to the new shop
  # @param items_sym [Array<Symbol, Integer>] the array containing the symbols/id of the items to sell
  # @param items_quantity [Array<Integer>] the array containing the quantity of the items to sell
  # @param shop_rewrite [Boolean] if the system must completely overwrite an already existing shop
  def add_limited_shop(symbol_of_shop, items_sym = [], items_quantity = [], shop_rewrite: false)
    PFM.game_state.shop.create_new_limited_shop(symbol_of_shop, items_sym, items_quantity, shop_rewrite: shop_rewrite)
  end
  alias ajouter_un_magasin_limite add_limited_shop

  # Add items to a limited shop
  # @param symbol_of_shop [Symbol] the symbol of the existing shop
  # @param items_to_refill [Array<Symbol, Integer>] the array of the items' db_symbol/id
  # @param quantities_to_refill [Array<Integer>] the array of the quantity to refill
  def add_items_to_limited_shop(symbol_of_shop, items_to_refill = [], quantities_to_refill = [])
    PFM.game_state.shop.refill_limited_shop(symbol_of_shop, items_to_refill, quantities_to_refill)
  end
  alias ajouter_objets_magasin add_items_to_limited_shop

  # Remove items from a limited shop
  # @param symbol_of_shop [Symbol] the symbol of the existing shop
  # @param items_to_remove [Array<Symbol, Integer>] the array of the items' db_symbol/id
  # @param quantities_to_remove [Array<Integer>] the array of the quantity to remove
  def remove_items_from_limited_shop(symbol_of_shop, items_to_remove, quantities_to_remove)
    PFM.game_state.shop.remove_from_limited_shop(symbol_of_shop, items_to_remove, quantities_to_remove)
  end
  alias enlever_objets_magasin remove_items_from_limited_shop

  # Open a Pokemon shop
  # @overload open_shop(items, prices)
  #   @param symbol_or_list [Symbol]
  #   @param prices [Hash] (optional)
  #   @param show_background [Boolean] (optional)
  # @overload open_shop(items,prices)
  #   @param symbol_or_list [Array<Integer, Symbol>]
  #   @param prices [Array<Integer>]
  #   @param param [Array<Hash, Integer>]
  #   @param show_background [Boolean] (optional)
  def pokemon_shop_open(symbol_or_list, prices = [], param = [], show_background: true)
    if symbol_or_list.is_a?(Symbol)
      GamePlay.open_existing_pokemon_shop(symbol_or_list, prices.is_a?(Hash) ? prices : {}, show_background: show_background)
    else
      GamePlay.open_pokemon_shop(symbol_or_list, prices, param, show_background: show_background)
    end
    @wait_count = 2
  end
  alias ouvrir_magasin_pokemon pokemon_shop_open

  # Create a limited Pokemon Shop
  # @param sym_new_shop [Symbol] the symbol to link to the new shop
  # @param list_id [Array<Integer>] the array containing the id of the Pokemon to sell
  # @param list_price [Array<Integer>] the array containing the prices of the Pokemon to sell
  # @param list_param [Array] the array containing the infos of the Pokemon to sell
  # @param list_quantity [Array<Integer>] the array containing the quantity of the Pokemon to sell
  # @param shop_rewrite [Boolean] if the system must completely overwrite an already existing shop
  def add_new_pokemon_shop(sym_new_shop, list_id, list_price, list_param, list_quantity = [], shop_rewrite: false)
    PFM.game_state.shop.create_new_pokemon_shop(sym_new_shop, list_id, list_price, list_param, list_quantity, shop_rewrite: shop_rewrite)
  end
  alias ajouter_nouveau_magasin_pokemon add_new_pokemon_shop

  # Add Pokemon to a Pokemon Shop
  # @param symbol_of_shop [Symbol] the symbol of the shop
  # @param list_id [Array<Integer>] the array containing the id of the Pokemon to sell
  # @param list_price [Array<Integer>] the array containing the prices of the Pokemon to sell
  # @param list_param [Array] the array containing the infos of the Pokemon to sell
  # @param list_quantity [Array<Integer>] the array containing the quantity of the Pokemon to sell
  # @param pkm_rewrite [Boolean] if the system must completely overwrite the existing Pokemon
  def add_pokemon_to_shop(symbol_of_shop, list_id, list_price, list_param, list_quantity = [], pkm_rewrite: false)
    PFM.game_state.shop.refill_pokemon_shop(symbol_of_shop, list_id, list_price, list_param, list_quantity, pkm_rewrite: pkm_rewrite)
  end
  alias ajouter_pokemon_au_magasin add_pokemon_to_shop

  # Remove Pokemon from a Pokemon Shop
  # @param symbol_of_shop [Symbol] the symbol of the existing shop
  # @param remove_list_mon [Array<Integer>] the array of the Pokemon id
  # @param param_form [Array<Hash>] the form of the Pokemon to delete (only if there is more than one form of a Pokemon in the list)
  # @param quantities_to_remove [Array<Integer>] the array of the quantity to remove
  def remove_pokemon_from_shop(symbol_of_shop, remove_list_mon, param_form, quantities_to_remove = [])
    PFM.game_state.shop.remove_from_pokemon_shop(symbol_of_shop, remove_list_mon, param_form, quantities_to_remove)
  end
  alias enlever_pokemon_du_magasin remove_pokemon_from_shop
end
