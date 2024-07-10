module Audio
  @known_drivers = { default: DriverBase }
  @selected_driver = :default
  module_function

  # Globally initialize the audio module (after all driver has been chosen and the game was loaded)
  def __init__
    # @type [DriverBase]
    @driver = @known_drivers[@selected_driver].new()
  end

  # Globally release the audio module (after the game is done or if you need to swap drivers)
  def __release__
    @driver&.release
    @driver = nil
  end

  # Globally reset the audio (when soft resetting the game or for other reasons)
  def __reset__
    @driver&.reset
  end

  # Update the audio (must be called every meaningful frames)
  def update
    @driver&.update
  end

  # Get the current driver
  # @return [DriverBase]
  def driver
    return @driver
  end

  # Register an audio driver
  # @param driver_name [Symbol] name of the driver
  # @param driver_class [Class<DriverBase>] driver class (to instanciate when chosen)
  def register_driver(driver_name, driver_class)
    @selected_driver = driver_name if @selected_driver != :fmod
    @known_drivers[driver_name] = driver_class
  end
end
