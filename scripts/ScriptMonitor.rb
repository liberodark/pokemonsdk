module ScriptLoader
  class ScriptMonitor
    def initialize
      @script_to_monitor = $LOADED_FEATURES.select { |f| f.match?(/\/scripts\/[0-9]{5}/) }
      load_last_mtimes
      start_monitoring
    end

    private

    def load_last_mtimes
      @last_mtimes = @script_to_monitor.map { |f| File.mtime(f) }
    end

    def start_monitoring
      @thread = Thread.new(&method(:monitor_loop))
      log_debug('Script are being monitored.')
    end

    def monitor_loop
      sleep(10) # Do not monitor for the first 10 seconds
      loop do
        break unless Graphics.window

        monitor
        sleep(1) # Monitor each seconds
      end
    end

    def monitor
      @script_to_monitor.each_with_index do |script, index|
        reload_script_if_necessary(script, index)
      end
    end

    def reload_script_if_necessary(script, index)
      current_mtime = File.mtime(script)
      return if current_mtime <= @last_mtimes[index]

      log_debug("Reloading: #{get_nice_name(script)}")
      @last_mtimes[index] = current_mtime
      reload_script(script)
    end

    def reload_script(script)
      original_verbose = $VERBOSE
      $VERBOSE = nil
      Kernel.load(script)
    rescue Exception
      log_error('Failed to load script...')
    ensure
      $VERBOSE = original_verbose
    end

    def get_nice_name(script)
      script.sub(VSCODE_SCRIPT_PATH, 'studio://scripts').sub(PROJECT_SCRIPT_PATH, 'project://scripts')
    end
  end
end
