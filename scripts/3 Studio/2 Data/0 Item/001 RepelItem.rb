module Studio
  # Data class describing an Item that repels creature for a certain amount of step
  class RepelItem < Item
    # Get the number of steps this item repels
    # @return [Integer]
    attr_reader :repel_count
  end
end

PFM::ItemDescriptor.define_bag_use(Studio::RepelItem, true) do |item, scene|
  if PFM.game_state.get_repel_count <= 0
    $game_temp.last_repel_used_id = item.id
    next PFM.game_state.set_repel_count(Studio::RepelItem.from(item).repel_count)
  end

  scene.display_message_and_wait(parse_text(22, 47))
  next :unused
end
