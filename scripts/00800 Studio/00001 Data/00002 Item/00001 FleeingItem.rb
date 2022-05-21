module Studio
  # Data class describing an Item that let the player flee battles
  class FleeingItem < Item
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::FleeingItem) do
  !$game_temp.in_battle
end
PFM::ItemDescriptor.define_bag_use(Studio::FleeingItem, true) do |item, scene|
  GamePlay.bag_mixin.from(scene).battle_item_wrapper = PFM::ItemDescriptor.actions(item.id)
  $scene = scene.__last_scene # This prevent the message from displaying now
end
