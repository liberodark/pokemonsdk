module Graphics
  # Proc stored to soft quit
  @on_close = proc {
    if $scene
      # Tell the GamePlay::Base scene to quit
      $scene.instance_variable_set(:@running, false)
      # Tell main not to continue to update (& Scene_Map to quit)
      $scene = nil
    end
    next(false) # Prevent the game from quitting
  }
end