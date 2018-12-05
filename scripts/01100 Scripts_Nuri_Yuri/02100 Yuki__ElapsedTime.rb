module Yuki
  # Module that allow to mesure elapsed time between two calls of #show
  #
  # This module is muted when $RELEASE = true
  #
  # Example :
  #   Yuki::ElapsedTime.start(:test)
  #   do_something
  #   Yuki::ElapsedTime.show(:test, "Something took")
  #   do_something_else
  #   Yuki::ElapsedTime.show(:test, "Something else took")
  module ElapsedTime
    @timers = {}
    @disabled_timers = []

    module_function

    # Start the time counter
    # @param name [Symbol] name of the timer
    def start(name)
      return if $RELEASE
      @timers[name] = Time.new
    end

    # Disable a timer
    # @param name [Symbol] name of the timer
    def disable_timer(name)
      @disabled_timers << name
    end

    # Enable a timer
    # @param name [Symbol] name of the timer
    def enable_timer(name)
      @disabled_timers.delete(name)
    end

    # Show the elapsed time between the current and the last call of show
    # @param name [Symbol] name of the timer
    # @param message [String] message to show in the console
    def show(name, message)
      return if $RELEASE
      timer = @timers[name]
      current_time = @timers[name] = Time.new
      delta_time = current_time - timer
      return sub_show(delta_time, message, 's') if delta_time > 1
      return sub_show(delta_time, message, 'ms') if (delta_time *= 1000) > 1
      return sub_show(delta_time, message, 'us') if (delta_time *= 1000) > 1
      sub_show(delta_time * 1000, message, 'ns')
    end

    # Show the real message in the console
    # @param delta [Float] number of unit elapsed
    # @param message [String] message to show on the terminal with the elapsed time
    # @param unit [String] unit of the elapsed time
    def sub_show(delta, message, unit)
      STDOUT.puts(format("\r[Yuki::ElapsedTime] %<message>s : %<delta>0.2f%<unit>s", message: message, delta: delta, unit: unit))
    end
  end
end