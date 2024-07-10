module Studio
  # Data class describing an Item that allow the player to catch a creature
  class BallItem < Item
    # Get the image of the ball
    # @return [String]
    attr_reader :sprite_filename
    # Get the rate of the ball in worse conditions
    # @return [Integer, Float]
    attr_reader :catch_rate
    # Get the color of the ball
    # @return [Color]
    attr_reader :color

    alias img sprite_filename
  end
end

PFM::ItemDescriptor.define_chen_prevention(Studio::BallItem) do
  next !$game_temp.in_battle || $game_temp.trainer_battle
end

PFM::ItemDescriptor.define_bag_use(Studio::BallItem, true) do |item, scene|
  battle_scene = scene.find_parent(Battle::Scene)
  if battle_scene.logic.alive_battlers(1).size > 1
    #TODO: Write text which says NO YOU CAN'T
    next :unused
  elsif battle_scene.player_actions.size > 1
    #TODO: Write text which says NO YOU CAN'T
    next :unused
  else
    GamePlay.bag_mixin.from(scene).battle_item_wrapper = PFM::ItemDescriptor.actions(item.id)
    #$scene = scene.__last_scene # This prevent the message from displaying now
    scene.return_to_scene(Battle::Scene)
  end
end

PFM::ItemDescriptor.define_chen_prevention(:rocket_ball) do
  next !$game_temp.in_battle
end

PFM::ItemDescriptor.define_bag_use(:rocket_ball, true) do |item, scene|
  battle_scene = scene.find_parent(Battle::Scene)
  if battle_scene.logic.alive_battlers(1).size > 1
    #TODO: Write text which says NO YOU CAN'T
    next :unused
  elsif battle_scene.player_actions.size > 1
    #TODO: Write text which says NO YOU CAN'T
    next :unused
  else
    GamePlay.bag_mixin.from(scene).battle_item_wrapper = PFM::ItemDescriptor.actions(item.id)
    #$scene = scene.__last_scene # This prevent the message from displaying now
    scene.return_to_scene(Battle::Scene)
  end
end
