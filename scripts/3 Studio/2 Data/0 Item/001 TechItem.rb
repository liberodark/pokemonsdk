module Studio
  # Data class describing an Item that allow a creature to learn a move
  class TechItem < Item
    # HM/TM text
    HM_TM_TEXT = '%s %s'
    # Get the db_symbol of the move it teaches
    # @return [Symbol]
    attr_reader :move
    # Get if the item is a Hidden Move or not
    # @return [Boolean]
    attr_reader :is_hm

    alias move_db_symbol move

    # Get the exact name of the item
    # @return [String]
    def exact_name
      return format(HM_TM_TEXT, name, data_move(move).name)
    end
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::TechItem) do
  next $game_temp.in_battle
end

PFM::ItemDescriptor.define_on_creature_usability(Studio::TechItem) do |item, creature|
  next false if creature.egg?

  next creature.can_learn?(Studio::TechItem.from(item).move)
end
