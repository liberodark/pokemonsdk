# Simple implementation of a clock
class Clock
  # Atomic delta value to avoid high imprecision due to big framerates
  ATOMIC_DELTA = 0.001

  # Get the clock speed factor
  # @return [Float, Integer]
  attr_reader :speed_factor

  # Create a new clock
  def initialize
    @elapsed_time = 0
    @last_time = Graphics.current_time
    @speed_factor = 1
    @frozen = false
  end

  # Reset the clock
  alias reset initialize

  # Tell if the clock is frozen
  # @return [Boolean]
  def frozen?
    return @frozen
  end

  # Freeze the clock
  def freeze
    return if frozen?
    @frozen = true
    tick
  end

  # Unfreeze the clock
  def unfreeze
    @last_time = Graphics.current_time
    @frozen = false
  end

  # Get the elapsed time (in seconds)
  # @return [Float]
  def elapsed_time
    tick unless frozen?
    return @elapsed_time
  end

  # Set the clock speed factor
  # @param speed_factor [Float, Integer]
  def speed_factor=(speed_factor)
    return unless speed_factor.is_a?(Float) || speed_factor.is_a?(Integer)

    @speed_factor = speed_factor
  end

  private

  # Tick the clock (add time to elapsed time)
  def tick
    return if Graphics.current_time == @last_time

    delta = (Graphics.current_time - @last_time) * @speed_factor
    return if delta < ATOMIC_DELTA

    @elapsed_time += delta
    @last_time = Graphics.current_time
  end

  # Main clock in case scene is not implementing any
  @main = new

  class << self
    # Get the main clock
    # @return [Clock]
    attr_reader :main
  end
end
