module ScriptLoader
  # Path of the scripts of PSDK
  VSCODE_SCRIPT_PATH = PSDK_PATH.gsub('\\','/') + '/scripts'
  # Path of the scripts of the Project
  PROJECT_SCRIPT_PATH = 'scripts'
  
  module_function
  
  # Start the script loading sequence
  def start
    # Load PSDK Scripts
    load_vscode_scripts(VSCODE_SCRIPT_PATH)
    # Load Project Scripts
    load_vscode_scripts(PROJECT_SCRIPT_PATH)
  end

  # Load all VSCODE like script from a path and its first level sub paths
  # @param path [String]
  def load_vscode_scripts(path)
    puts format('Loading %s...', path)
    load_scripts(path)
    Dir[File.join(path, '*/')].sort.each { |pathname| load_scripts(pathname) }
  end

  # Load all scripts from a path
  # @param path [String]
  # @note Scripts has to be named "$$$$$ scriptname.rb" where $ are digit
  def load_scripts(path)
    Dir[File.join(path, '*.rb')].sort.each { |filename| require(filename) if File.basename(filename) =~ /^[0-9]{5} .*/ }
  rescue StandardError
    if Object.const_defined?(:Yuki) and Yuki.const_defined?(:EXC)
      Yuki::EXC.run($!)
    else
      raise
    end
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