module ScriptLoader
  # Path of the scripts of PSDK
  VSCODE_SCRIPT_PATH = __FILE__.force_encoding(Encoding::UTF_8).tr('\\', '/').sub(%r{/[^/]+\.rb$}, '') # .sub(File.expand_path('.') + '/', '')
  # Path of the scripts of the Project
  PROJECT_SCRIPT_PATH = File.expand_path('scripts')
  # Path to the script index
  SCRIPT_INDEX_PATH = File.join(VSCODE_SCRIPT_PATH, 'script_index.txt')
  # Path to the deflate scripts
  DEFLATE_SCRIPT_PATH = File.join(VSCODE_SCRIPT_PATH, 'mega_script.deflate')
  # Path to the packed script file
  PACKED_SCRIPTS_PATH = File.join(VSCODE_SCRIPT_PATH, 'scripts.dat')
  # Regular expression for script folder
  SCRIPT_FOLDER_REG = %r{/[0-9]+[ _][^/]+/$}i

  module_function

  # Start the script loading sequence
  def start
    @should_build_script = ARGV.include?('pack_scripts') && !ARGV.include?('studio')
    File.delete(PACKED_SCRIPTS_PATH) if File.exist?(DEFLATE_SCRIPT_PATH)
    return load_packed_scripts if !@should_build_script && File.exist?(PACKED_SCRIPTS_PATH) && PARGV[:util].to_a.none? { |util| util.start_with?('project_compilation') }

    unpack_scripts if File.exist?(DEFLATE_SCRIPT_PATH)
    # Load PSDK Scripts
    if File.exist?(index_filename)
      load_script_from_index
    elsif PARGV.game_launched_by_studio?
      STDERR.puts({ type: :load_error, message: 'Script Index is missing' }.to_json)
      Process.exit!(1)
    else
      File.open(SCRIPT_INDEX_PATH, 'w') do |file|
        load_vscode_scripts(VSCODE_SCRIPT_PATH, file)
      end
    end
    load_vscode_scripts(PROJECT_SCRIPT_PATH) if PARGV[:util].include?('project_compilation') && index_filename == SCRIPT_INDEX_PATH
    return if PARGV[:util].any?
    return if PARGV.game_launched_by_studio?

    load_rmxp_scripts
    load_plugins
    # Load Project Scripts
    load_vscode_scripts(PROJECT_SCRIPT_PATH) if index_filename == SCRIPT_INDEX_PATH
    save_packed_scripts if @should_build_script
    if PARGV[:mon]
      require_relative 'ScriptMonitor'
      @monitor = ScriptMonitor.new
    end
  end

  # Load the script from the packed archive
  def load_packed_scripts
    data = Marshal.load(Zlib::Inflate.inflate(File.binread(PACKED_SCRIPTS_PATH)))
    iseq = RubyVM::InstructionSequence
    data.each { |script| iseq.load_from_binary(script).eval }
  end

  # Save the packed scripts
  def save_packed_scripts
    return unless @scripts_iseqs

    data = Zlib::Deflate.deflate(Marshal.dump(@scripts_iseqs))
    return if File.exist?(PACKED_SCRIPTS_PATH) && data == File.binread(PACKED_SCRIPTS_PATH)

    File.binwrite(PACKED_SCRIPTS_PATH, data)
  end

  # Pack a script
  # @param filename [String]
  def pack_script(filename)
    @scripts_iseqs ||= []
    script_filename = filename.sub(VSCODE_SCRIPT_PATH, 'PSDK').sub(File.expand_path('.'), 'USER')
    @scripts_iseqs << RubyVM::InstructionSequence.compile(File.read(filename), script_filename, '.').to_binary
  end

  # Load all VSCODE like script from a path and its first level sub paths
  # @param path [String]
  # @param file [File, nil] file used to store the script name
  def load_vscode_scripts(path, file = nil)
    puts format('Loading %<path>s...', path: path)
    load_scripts(path, file)
    Dir[File.join(path, '*/')].grep(SCRIPT_FOLDER_REG).sort.each { |pathname| load_vscode_scripts(pathname, file) }
  end

  # Load all scripts from a path
  # @param path [String]
  # @param file [File, nil] file used to store the script name
  # @note Scripts has to be named "$$$$$ scriptname.rb" where $ are digit
  def load_scripts(path, file = nil)
    Dir[File.join(path, '*.rb')].sort.each do |filename|
      next unless File.basename(filename) =~ /^[0-9]{5}[ _].*/

      require(filename)
      pack_script(filename) if @should_build_script
      file&.puts(filename.sub(File.expand_path('.') + '/', ''))
    rescue Exception
      if PARGV.game_launched_by_studio?
        STDERR.puts({ type: :load_error, message: "Script: #{filename} is corrupted", klass: $!.class.to_s, error_message: $!.message }.to_json)
        Process.exit!(1)
      elsif Object.const_defined?(:Yuki) && Yuki.const_defined?(:EXC)
        Yuki::EXC.run($!)
        puts $!.message
        puts $!.backtrace.join("\n")
        print 'Retry ? [y/n]: '
        retry if gets.chomp.downcase == 'y'
      else
        raise
      end
    end
  end

  # Load the PSDK scripts from the index
  def load_script_from_index
    lines = File.readlines(index_filename)
    if Dir.exist?('pokemonsdk')
      path = ENV['ALTERNATIVE_PATH'] || '.'
      puts 'Scripts loaded from the project codebase'
    else
      path = ENV['ALTERNATIVE_PATH'] || ENV['PSDK_BINARY_PATH']&.tr('\\', '/') || '.'
      puts 'Scripts loaded from the Studio codebase'
    end
    lines.each do |filename|
      require(File.join(path, filename.chomp))
      pack_script(File.join(path, filename.chomp)) if @should_build_script
    end
  rescue Exception
    if PARGV.game_launched_by_studio?
      STDERR.puts({ type: :load_error, message: 'A script could not load', klass: $!.class.to_s, error_message: $!.message }.to_json)
      Process.exit!(1)
    else
      STDERR.puts $!.message
      STDERR.puts $!.backtrace.join("\n")
    end
  end

  def mkdir(*args)
    curr = args.shift
    Dir.mkdir(curr) unless Dir.exist?(curr)
    args.each do |dirname|
      curr = File.join(curr, dirname)
      Dir.mkdir(curr) unless Dir.exist?(curr)
    end
  end

  # Unpack the scripts
  def unpack_scripts
    hash = Marshal.load(Zlib::Inflate.inflate(File.binread(DEFLATE_SCRIPT_PATH)))
    hash.each do |filename, contents|
      dirname = File.dirname(filename)
      mkdir(*dirname.split('/')) unless Dir.exist?(dirname)
      File.binwrite(filename, contents)
    end
    File.delete(DEFLATE_SCRIPT_PATH)
  end

  # Return the script index filename (taken according to the context)
  # @return [String]
  def index_filename
    return @index_filename if @index_filename
    if !ARGV.grep(/\-\-util[ =]update$/).empty?
      @index_filename = File.join(VSCODE_SCRIPT_PATH, 'script_update_index.txt')
      # Prevent RMXP Scripts from loading
      Kernel.define_method(:eval) { |*args| }
    elsif !(matches = ARGV.grep(/\-\-script_context[ =].+\.txt$/)).empty?
      @index_filename = File.join(VSCODE_SCRIPT_PATH, matches.first.match(/\-\-script_context[ =](.*)/).captures.first)
      # We also don't want custom script in that context
      Kernel.define_method(:eval) { |*args| }
    else
      @index_filename = SCRIPT_INDEX_PATH
    end
    puts "Script Index : #{@index_filename}" unless PARGV.game_launched_by_studio?
    return @index_filename
  end

  # Load the RMXP scripts
  def load_rmxp_scripts
    @scripts_iseqs ||= []
    ban1 = 'config'
    ban2 = 'boot'
    ban3 = '_'
    iseq = RubyVM::InstructionSequence
    load_data('Data/Scripts.rxdata').each do |script|
      # @type [String]
      name = script[1].force_encoding(Encoding::UTF_8)
      next if name.downcase.start_with?(ban1, ban2, ban3)

      ruby_script = Zlib::Inflate.inflate(script[2]).force_encoding(Encoding::UTF_8)
      eval(ruby_script, TOPLEVEL_BINDING, name)
      @scripts_iseqs << iseq.compile(ruby_script, "RMXP/#{name}", '.').to_binary
      GC.start
    end
  end

  # Load a tool script
  # @param relative_path [String] path from pokemonsdk/scripts/tools to access to the script
  def load_tool(relative_path)
    require "#{VSCODE_SCRIPT_PATH}/tools/#{relative_path}"
  end

  # Load the plugin manager & the plugin (install)
  def load_plugins
    ScriptLoader.load_tool('PluginManager')
    PluginManager.start(:load)
  rescue Exception
    pcc "Plugins couldn't be loaded or installed..."
  end
end

# Defaulting some old internal PSDK function
module Kernel
  def cc(*)
    0
  end
end
alias pc puts
