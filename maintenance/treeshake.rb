# This script helps people to convert the whole ruby std lib PSDK needs into a single file that can be loaded without involving the ruby parser
# Usage:
# ruby --disable=gems,rubyopt,did_you_mean threeshake.rb [lib1,lib2,lib3]
# Note: The order of lib loading might be important, some library lazy load stuff which is pretty unsustainable, if you face this, add lazy loaded lib before other lib!
require 'zlib'

def cleanup_paths(paths)
  return paths.reject { |path| File.directory?(path) || path.include?('/bundler/') || path.include?('/irb/') || path.include?('/rdoc/') || path.include?('/optparse/')  || path.include?('/rubygems/') }
end

def load_all_dependencies_filenames
  sorted_load_path = $LOAD_PATH.sort_by(&:size).reverse
  all_paths = sorted_load_path.map { |f| cleanup_paths(Dir["#{f}/**/*.*"]) }
  return all_paths.map.with_index do |paths, i|
    all_paths.each_with_index do |other_paths, j|
      break if i == j

      paths -= other_paths
    end
    next paths
  end.flatten.sort_by(&:size)
end

def get_binary_extensions(all_paths)
  all_paths.map { |path| File.extname(path) }.uniq - ['.rb', '.pem']
end

def load_binary_dependency(dependency_name)
  dependency_name = dependency_name.sub('.so', '') if dependency_name.end_with?('.so')
  BINARY_EXTENSIONS.each do |ext|
    binary_filename = "/#{dependency_name}#{ext}"
    binary_filename = ALL_DEPENDENCIES.find { |f| f.end_with?(binary_filename) }
    next unless binary_filename
    return "# already-loaded: #{dependency_name}" if ALREADY_LOADED_FEATURES.include?(binary_filename)

    ALREADY_LOADED_FEATURES << binary_filename
    return "require '#{dependency_name}#{ext}'" if binary_filename
  end
  STDERR.puts "Failed to find dependency #{dependency_name}"
  return "require '#{dependency_name}'"
end

def load_dependency(dependency_name)
  ruby_filename = "/#{dependency_name}.rb"
  ruby_filename = ALL_DEPENDENCIES.find { |f| f.end_with?(ruby_filename) }
  return load_binary_dependency(dependency_name) unless ruby_filename
  return "# already-loaded: #{dependency_name}" if ALREADY_LOADED_FEATURES.include?(ruby_filename)

  ALREADY_LOADED_FEATURES << ruby_filename
  filtered = File.read(ruby_filename).gsub(REQUIRE_DETECT_REG) do |require_line|
    sub_dep = require_line.match(REQUIRE_DETECT_REG).captures.compact.first
    if require_line.match?(/^[ \t]*require_relative/) && File.dirname(dependency_name) != '.'
      sub_dep = File.join(File.dirname(dependency_name), sub_dep)
    end
    load_dependency(sub_dep)
  end

  return "$LOADED_FEATURES << \"\#{$LOAD_PATH[0]}/#{dependency_name}.rb\"\n#{filtered}"
end

ALL_DEPENDENCIES = load_all_dependencies_filenames
REQUIRE_DETECT_REG = /^[ \t]*require(?:_relative|)(?: "([^"]+)"|\("([^"]+)"\)| '([^']+)'|\('([^']+)'\))/
BINARY_EXTENSIONS = get_binary_extensions(ALL_DEPENDENCIES)
ALREADY_LOADED_FEATURES = []
# Rejecting RbConfig from library since it leaks stuff that the game does not need to know
load_dependency('rbconfig')
# Rejecting win32/sspi since it's disabled and adds Fiddle (which is highly unwanted)
load_dependency('win32/sspi')
# Extensions to load
extensions = [
  'stringio', # 'zlib',
  'socket','openssl','securerandom','bigdecimal', # 'rbconfig',
  'tempfile','delegate',
  'json/ext','json','forwardable/impl', 'forwardable',
  'uri','net/http', 'csv', 'psych/syntax_error','psych', 'yaml']
extensions.push(ARGV[0].split(',')) if ARGV[0]

all_extensions = extensions.map { |dep| load_dependency(dep) }# .join("\n#<!--->\n")
# File.write('all_extensions.rb', all_extensions)
# exit

compiled = all_extensions.map.with_index do |e,i|
  name = extensions[i] + '.rb'
  RubyVM::InstructionSequence.compile(e, name, name).to_binary
end
File.binwrite('ruby-lib', Zlib::Deflate.deflate(Marshal.dump(compiled)))

# File.write('all_extensions2.rb', <<~EOF)
#   require 'zlib'
#   Marshal.load(Zlib::Inflate.inflate(File.binread('ext.dat'))).each do |e|
#     RubyVM::InstructionSequence.load_from_binary(e).eval
#   end
# EOF
