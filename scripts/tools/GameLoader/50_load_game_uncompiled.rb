boot_time = Time.new

# Loading all the game scripts
begin
  puts 'Loading Game...'
  ScriptLoader.load_tool('GameLoader/Z_main') unless PARGV[:util].to_a.any?
  ScriptLoader.start
  SafeExec.load
  GC.start
rescue StandardError
  display_game_exception('An error occured during Script Loading.')
end

# Loading all the utility
begin
  PARGV[:util].to_a.each do |filename|
    if filename.start_with?('project_compilation')
      ScriptLoader.load_tool('Compilation/project_compilation')
    elsif filename.start_with?('eventtext2csv')
      ScriptLoader.load_tool('EventText2CSV')
      EventText2CSV.run
    elsif filename.start_with?('convert')
      ScriptLoader.load_tool('ProjectToYAML')
      ProjectToYAML.convert
    elsif filename.start_with?('restore')
      ScriptLoader.load_tool('ProjectToYAML')
      ProjectToYAML.restore
    elsif filename.start_with?('build_state_machine')
      ScriptLoader.load_tool('StateMachineBuilder/StateMachineBuilder')
      argv = ARGV.reject { |arg| arg.start_with?('-') }
      argv.each { |machine_filename| StateMachineBuilder.run(machine_filename) } if argv[0]
    else
      require filename
    end
  end
  pausable_util = /(update)/
  system('pause') if !PARGV[:util].empty? && PARGV[:util].any? { |util| util.match?(pausable_util) }
  if File.exist?(fn = 'Data/Tiled/.jobs/map_jobs.json') && File.size(fn) > 6
    ScriptLoader.load_tool('Tiled2Rxdata/Tiled2Rxdata')
  end
rescue StandardError
  display_game_exception('An error occured during Utility loading...')
end

# Actually start the game
begin
  puts format('Time to boot game : %<time>ss', time: (Time.new - boot_time))
  $GAME_LOOP&.call
rescue Exception
  display_game_exception('An error occured during Game Loop.')
end
