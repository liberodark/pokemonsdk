module Studio
  # Data class describing an Item that let the player flee battles
  class FleeingItem < Item
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::FleeingItem) do
  next !$game_temp.in_battle || $game_temp.trainer_battle || $game_switches[Yuki::Sw::BT_NoEscape]
end
PFM::ItemDescriptor.define_bag_use(Studio::FleeingItem, true) do |item, scene|
  GamePlay.bag_mixin.from(scene).battle_item_wrapper = PFM::ItemDescriptor.actions(item.id)
  $scene = scene.__last_scene # This prevent the message from displaying now
  scene.return_to_scene(Battle::Scene)
end
