module GamePlay
  # Battle specialization of the bag
  class Battle_Bag < Bag
    # Create a new Battle_Bag
    # @param team [Array<PFM::PokemonBattler>] party that use this bag UI
    def initialize(team)
      super(:battle)
      @team = team
    end

    # Load the list of item (ids) for the current pocket
    def load_item_list
      if pocket_id == FAVORITE_POCKET_ID
        @item_list = $bag.get_order(:favorites)
      else
        @item_list = $bag.get_order(pocket_id)
      end
      @item_list = @item_list.select { |item| data_item(item).is_battle_usable }
      @index = 0
      @last_index = @item_list.size
    end
    alias reload_item_list load_item_list
  end
end

GamePlay.battle_bag_class = GamePlay::Battle_Bag
