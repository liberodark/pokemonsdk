# Constant telling on which platform PSDK is running (:windows, :android, :macos, :unix)
PSDK_PLATFORM = -> () do
  next :windows if !ENV['windir'].nil?
  next :android if RUBY_PLATFORM.include? "android"
  next :macos if RUBY_PLATFORM.include? "darwin"
  next :unix
end.call

# Constant telling where the PSDK libs are
PSDK_LIB_PATH = -> () do
  next '' if PSDK_PLATFORM == :android

  game_deps = (ENV['GAMEDEPS'] || ENV['PSDK_BINARY_PATH'] || '.').tr('\\', '/')
  next File.join(game_deps, 'lib') if PSDK_PLATFORM == :windows
  next File.join(game_deps, 'ruby-dist', 'lib')
end.call

# Constant telling where is the PSDK master installation
PSDK_PATH =
  (Dir.exist?('pokemonsdk') && File.expand_path('pokemonsdk')) ||
  (ENV['PSDK_BINARY_PATH'] && File.join(ENV['PSDK_BINARY_PATH'].tr('\\', '/'), 'pokemonsdk')) ||
  ((ENV['APPDATA'] || ENV['HOME']).dup.force_encoding('UTF-8') + '/.pokemonsdk')

$LOAD_PATH << './plugins' unless $LOAD_PATH.include?('./plugins')

ENV['SSL_CERT_FILE'] ||= './lib/cert.pem' if $0 == 'Game.rb' # Launched from PSDK

# Constant giving the current PSDK version
PSDK_VERSION = File.read("#{PSDK_PATH}/version.txt").to_i
# Constant giving the current PSDK version as human readable version
PSDK_VERSION_STRING = [PSDK_VERSION].pack('I>').unpack('C*').join('.').gsub(/^(0\.)+/, '')

puts("\e[31mPSDK Version : #{PSDK_VERSION_STRING}\e[37m")
