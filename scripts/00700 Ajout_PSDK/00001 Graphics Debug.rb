module Graphics
  class << self
    private

    def io_initialize
      STDOUT.sync = true unless STDOUT.tty?
      return if PSDK_CONFIG.release?

      @cmd_thread = create_command_thread
    rescue StandardError
      puts 'Failed to initialize IO related things'
    end
    Hooks.register(Graphics, :init_sprite, 'PSDK Graphics io_initialize') { io_initialize }

    # Create the Command thread
    def create_command_thread
      Thread.new do
        loop do
          log_info('Type help to get a list of the commands you can use.')
          print 'Command: '
          @__cmd_to_eval = STDIN.gets.chomp
          sleep
        rescue StandardError
          @cmd_thread = nil
          @__cmd_to_eval = nil
          break
        end
      end
    end

    # Eval a command from the console
    def update_cmd_eval
      return unless (cmd = @__cmd_to_eval)
      @__cmd_to_eval = nil
      begin
        if cmd.match?(/^Game /i)
          system(PSDK_RUNNING_UNDER_WINDOWS ? "start #{cmd}" : cmd)
          exit!
        end
        puts Object.instance_eval(cmd)
      rescue StandardError, SyntaxError
        print "\r"
        puts "#{$!.class} : #{$!.message}"
        puts $!.backtrace
      end
      @cmd_thread&.wakeup
    end
    Hooks.register(Graphics, :post_update_internal, 'PSDK Graphics update_cmd_eval') { update_cmd_eval }
  end
end
