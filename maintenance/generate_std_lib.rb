# This script helps to create the custom std-lib folder with a single yarb file to load all the ruby code of the game's std-lib
# This script internally invoke treeshake.rb
# How to run: ruby --disable=gems,rubyopt,did_you_mean generate_std_lib.rb dest_folder [lib1,lib2,...]
# Example from the pokemonsdk folder in psdk-binaries: ..\ruby --disable=gems,rubyopt,did_you_mean generate_std_lib.rb ../lib-m

extensions_to_load = ['zlib', 'stringio', 'securerandom','bigdecimal','socket','uri','openssl','net/http','csv','json', 'yaml']
extensions_to_load.concat(ARGV[1].split(',')) if ARGV[1]

previous_loaded_features = $LOADED_FEATURES.dup
extensions_to_load.each { |e| require(e) }
diff_loaded_features = $LOADED_FEATURES - previous_loaded_features
$LOAD_PATH_BY_SIZE = $LOAD_PATH.sort_by(&:size).reverse


ruby_files = diff_loaded_features.select { |f| f.end_with?('.rb') }
binary_files = diff_loaded_features - ruby_files
psych_so = binary_files.find { |f| f.end_with?('socket.so') }
binary_files.concat(Dir["#{File.dirname(psych_so)}/enc/**/*.so"])
lib_base_path = diff_loaded_features[0].split('/lib/ruby/')[0] + '/lib'
treeshake = File.expand_path('treeshake.rb')

puts "Ruby lib base path: #{lib_base_path}"

def mkdir(dir)
  return if Dir.exist?(dir)

  mkdir(File.dirname(dir))
  Dir.mkdir(dir)
end

mkdir(ARGV[0]) unless Dir.exist?(ARGV[0])
Dir.chdir(ARGV[0]) do
  ARGV[0] = ARGV[1]
  load(treeshake)

  binary_files.each do |f|
    target_filename = f.sub(lib_base_path, '.')
    target_dirname = File.dirname(target_filename)
    mkdir(target_dirname)
    IO.copy_stream(f, target_filename)
  end
end
