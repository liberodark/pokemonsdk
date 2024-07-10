module Studio
  # Data class describing an Item that calls an event in map
  class EventItem < Item
    # Get the ID of the event to call
    # @return [Integer]
    attr_reader :event_id
  end
end

PFM::ItemDescriptor.define_bag_use(Studio::EventItem, true) do |item, scene|
  condition = PFM::ItemDescriptor::COMMON_EVENT_CONDITIONS[Studio::EventItem.from(item).event_id]
  if condition.call
    $game_temp.common_event_id = Studio::EventItem.from(item).event_id
  else
    scene.display_message_and_wait(parse_text(22, 43))
    next :unused
  end
end
