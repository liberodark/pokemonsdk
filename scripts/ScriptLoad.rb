module ScriptLoader
  # Path of the scripts of PSDK
  VSCODE_SCRIPT_PATH = PSDK_PATH.gsub('\\','/') + '/scripts'
  # Path of the scripts of the Project
  PROJECT_SCRIPT_PATH = 'scripts'
  # Path to the script index
  SCRIPT_INDEX_PATH = File.join(VSCODE_SCRIPT_PATH, 'script_index.txt')
  # Path to the deflate scripts
  DEFLATE_SCRIPT_PATH = File.join(VSCODE_SCRIPT_PATH, 'mega_script.deflate')
  
  module_function
  
  # Start the script loading sequence
  def start
    unpack_scripts if File.exist?(DEFLATE_SCRIPT_PATH)
    # Load PSDK Scripts
    if File.exist?(SCRIPT_INDEX_PATH)
      load_script_from_index
    else
      File.open(SCRIPT_INDEX_PATH, 'w') do |file|
        load_vscode_scripts(VSCODE_SCRIPT_PATH, file)
      end
    end
    # Load Project Scripts
    load_vscode_scripts(PROJECT_SCRIPT_PATH)
  end

  # Load all VSCODE like script from a path and its first level sub paths
  # @param path [String]
  # @param file [File, nil] file used to store the script name
  def load_vscode_scripts(path, file = nil)
    puts format('Loading %s...', path)
    load_scripts(path, file)
    Dir[File.join(path, '*/')].sort.each { |pathname| load_scripts(pathname, file) }
  end

  # Load all scripts from a path
  # @param path [String]
  # @param file [File, nil] file used to store the script name
  # @note Scripts has to be named "$$$$$ scriptname.rb" where $ are digit
  def load_scripts(path, file = nil)
    Dir[File.join(path, '*.rb')].sort.each do |filename|
      next unless File.basename(filename) =~ /^[0-9]{5}[ _].*/
      file.puts(filename) if file
      require(filename)
    end
  rescue StandardError
    if Object.const_defined?(:Yuki) and Yuki.const_defined?(:EXC)
      Yuki::EXC.run($!)
    else
      raise
    end
  end
  
  # Load the PSDK scripts from the index
  def load_script_from_index
    lines = File.readlines(SCRIPT_INDEX_PATH)
    lines.each do |filename|
      require(filename.chomp)
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
      File.write(filename, contents)
    end
    File.delete(DEFLATE_SCRIPT_PATH)
  end
end

# Defaulting some old internal PSDK function
module Kernel
  def cc(*)
    0
  end
end
alias pc puts
# Starting script loading
ScriptLoader.start