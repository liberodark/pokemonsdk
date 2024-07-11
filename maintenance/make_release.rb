Dir.chdir('..')
$skipping_docs = ARGV.include?('skip_docs')
$skipping_yard_doc = ARGV.include?('skip_yard')

# Combine all the modules in a script together while preserving documentation
# @param filename [String] filename of the file holding the modules to combine
# @param destination_filename [String] destination filename for the result
def documentation_with_method_body(filename, destination_filename)
  IO.popen(['ruby-code-rewrite.exe', filename, 'documentation_with_method_body']) do |f|
    IO.write(destination_filename, f.read)
  end
end


# Combine all the modules in a script together while erasing method bodies to only have documentation
# @param filename [String] filename of the file holding the modules to combine
# @param destination_filename [String] destination filename for the result
def documentation(filename, destination_filename)
  IO.popen(['ruby-code-rewrite.exe', filename, 'documentation']) do |f|
    IO.write(destination_filename, f.read)
  end
end

RELEASE_FOLDER = '.release'
RELEASE_DOCS = '.release/docs'
RELEASE_SCRIPTS = '.release/scripts'

SCRIPT_GROUPS = [
  '0 Dependencies/',
  '1 RMXP Scripts/',
  '2 PSDK Event Interpreter/',
  '3 Studio/',
  '4 Systems/000 General/1 PFM/',
  '4 Systems/000 General/2 GamePlay__Base',
  '4 Systems/000 General/3 GameState',
  '4 Systems/000 General/4 UI Generics',
  '4 Systems/000 General/',
  '4 Systems/001 Title/',
  '4 Systems/002 Credits/',
  '4 Systems/003 Map Engine/',
  '4 Systems/004 Message/',
  '4 Systems/005 Animation/',
  '4 Systems/100 Menu/',
  '4 Systems/101 Dex/',
  '4 Systems/102 Party/',
  '4 Systems/103 Bag/',
  '4 Systems/104 Trainer/',
  '4 Systems/105 Options/',
  '4 Systems/106 Save Load/',
  '4 Systems/200 Storage/',
  '4 Systems/201 Daycare/',
  '4 Systems/202 Environment/',
  '4 Systems/203 Shop/',
  '4 Systems/204 Nuzlocke/',
  '4 Systems/205 Input/',
  '4 Systems/206 TownMap/',
  '4 Systems/207 Shortcut/',
  '4 Systems/300 Hall of fame/',
  '4 Systems/301 MoveTeaching/',
  '4 Systems/302 MoveReminder/',
  '4 Systems/303 Evolve/',
  '4 Systems/400 RSE Clock/',
  '4 Systems/800 Quest/',
  '4 Systems/801 Mining Game/',
  '4 Systems/900 Games/',
  '4 Systems/901 GTS/',
  '4 Systems/950 Movie/',
  '4 Systems/951 DynamicLight/',
  '4 Systems/998 Global Systems/',
  '4 Systems/999 Wild/',
  '5 Battle/01 Scene/',
  '5 Battle/02 Visual/',
  '5 Battle/03 PokemonBattler/',
  '5 Battle/04 Logic/',
  '5 Battle/05 Actions/',
  '5 Battle/06 Effects/01 Mechanics/',
  '5 Battle/06 Effects/02 Move Effects/',
  '5 Battle/06 Effects/03 Status Effects/',
  '5 Battle/06 Effects/04 Ability Effects/',
  '5 Battle/06 Effects/05 Item Effects/',
  '5 Battle/06 Effects/06 Weather Effects/',
  '5 Battle/06 Effects/07 Field Terrain Effects/',
  '5 Battle/06 Effects/10 O-Power Effects/',
  '5 Battle/06 Effects/11 Trainer Effects/',
  '5 Battle/06 Effects/',
  '5 Battle/10 Move/00001 Mechanics/',
  '5 Battle/10 Move/00010 Definitions/',
  '5 Battle/10 Move/',
  '5 Battle/20 MoveAnimation/',
  '5 Battle/30 AI/1 MoveHeuristic/',
  '5 Battle/30 AI/',
  '5 Battle/99 Pokemon Script Project/',
  '9 Loaded Last/'
]

def combine_scripts
  index = File.readlines('scripts/script_index.txt').map { |l| l.strip.sub('pokemonsdk/scripts/', '') }
  groups = index.group_by { |l| SCRIPT_GROUPS.find { |g| l.start_with?(g) } || '000_a_root' }
  new_script_index = []
  groups.each do |key, scripts|
    target_filename = key.gsub('/', ' ').strip.gsub(' ', '_') << '.rb'
    new_script_index << "pokemonsdk/scripts/#{target_filename}"
    script_filename = File.join(RELEASE_SCRIPTS, target_filename)
    doc_filename = File.join(RELEASE_DOCS, target_filename)
    File.write(script_filename, scripts.map { |f| File.read("scripts/#{f}") }.join("\n\n"))
    documentation(script_filename, doc_filename) unless $skipping_docs
    documentation_with_method_body(script_filename, script_filename)
  end
  File.write(File.join(RELEASE_SCRIPTS, 'script_index.txt'), new_script_index.join("\n"))
end

def move_documentation_files
  files_to_move = Dir['*.md']
  files_to_doc = files_to_move.map { |f| f.sub('# ', '').gsub(' ', '_').gsub('.25', 'dot_25') }
  operations = [files_to_move, files_to_doc].transpose.to_h
  # Readme is a special file so it doesn't need to be in files to doc
  files_to_doc.delete('README.md')
  # Copy files
  operations.each do |source, destination|
    IO.copy_stream(source, File.join(RELEASE_FOLDER, destination))
  end
  # Write yard configuration
  File.write(File.join(RELEASE_FOLDER, '.yardopts'), <<~YARDOPTS)
  --hide-void-return
  --default-return ''
  --title "Pokemon SDK"
  --exclude "scripts/*.rb"
  --readme README.md
  --output-dir yard-docs
  --no-private docs/*.rb
  --no-private docs/**/*.rb
  --plugin junk
  LiteRGSS.rb.yard.rb
  docs/*.rb

  - "#{files_to_doc.join('" "')}"
  YARDOPTS
end

# Begin of the release process
Dir.mkdir(RELEASE_FOLDER) unless Dir.exist?(RELEASE_FOLDER)
Dir.mkdir(RELEASE_DOCS) unless Dir.exist?(RELEASE_DOCS)
Dir.mkdir(RELEASE_SCRIPTS) unless Dir.exist?(RELEASE_SCRIPTS)

unless ARGV.include?('skip_scripts')
  Dir[File.join(RELEASE_SCRIPTS, '**/*.*')].each { |f| File.delete(f) }
  Dir[File.join(RELEASE_DOCS, '*')].each { |f| File.delete(f) }

  combine_scripts
  IO.copy_stream('maintenance/LiteRGSS.rb.yard.rb', File.join(RELEASE_FOLDER, 'LiteRGSS.rb.yard.rb'))
end

unless $skipping_yard_doc
  move_documentation_files
  Dir.chdir(RELEASE_FOLDER) do
    system('yard doc')
  end
end