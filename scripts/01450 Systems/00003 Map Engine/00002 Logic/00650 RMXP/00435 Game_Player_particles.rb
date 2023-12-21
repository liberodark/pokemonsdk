class Game_Player < Game_Character
  # Push the sand particle only if the player is not cycling
  def particle_push_sand
    super unless cycling?
  end
end