module Studio
  # Data class describing an Item (see 00002 Item folder for functional items)
  class Item
    # List of get item ME
    ItemGetME = %w[Audio/ME/ROSA_ItemObtained.ogg Audio/ME/ROSA_KeyItemObtained.ogg Audio/ME/ROSA_TMObtained.ogg]
    # ID of the item
    # @return [Integer]
    attr_reader :id

    # db_symbol of the item
    # @return [Symbol]
    attr_reader :db_symbol

    # Icon of the item (in the bag)
    # @return [String]
    attr_reader :icon

    # Price of the item (in the shop)
    # @return [Integer]
    attr_reader :price

    # Pocket of the item in the bag
    # @return [Integer]
    attr_reader :socket

    # Relative position of the item (in the socket) in ascending order
    # @return [Integer]
    attr_reader :position

    # If the item can be used in battle
    # @return [Boolean]
    attr_reader :is_battle_usable

    # If the item can be used in the overworld
    # @return [Boolean]
    attr_reader :is_map_usable

    # If the item must be consumed when used
    # @return [Boolean]
    attr_reader :is_limited

    # If the item can be held by a creature
    # @return [Boolean]
    attr_reader :is_holdable

    # Power of the Fling move when item is thrown
    # @return [Integer]
    attr_reader :fling_power

    # Get the name of the item
    # @return [String]
    def name
      return text_get(12, @id)
    end

    # Get the exact name of the item (including move name)
    # @return [String]
    def exact_name
      return name
    end

    # Name of the item in plural
    # @return [String]
    def plural_name
      return ext_text(9001, @id)
    end

    # Description of the item
    # @return [String]
    def description
      return text_get(13, @id)
    end
    alias descr description

    # Get the ME of the item when it's got
    # @return [String]
    def me
      return ItemGetME[2] if socket == 3
      return ItemGetME[1] if socket == 5

      return ItemGetME[0]
    end
  end
end
