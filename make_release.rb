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
  '00000 Dependencies/',
  '00600 Script_RMXP/',
  '00700 Ajout_PSDK/',
  '00700 PSDK Event Interpreter/',
  '00800 Studio/',
  '01450 Systems/00000 General/00001 PFM/',
  '01450 Systems/00000 General/00003 GamePlay__Base',
  '01450 Systems/00000 General/00010 GameState',
  '01450 Systems/00000 General/00100 UI Generics',
  '01450 Systems/00000 General/',
  '01450 Systems/00001 Title/',
  '01450 Systems/00002 Credits/',
  '01450 Systems/00003 Map Engine/',
  '01450 Systems/00004 Message/',
  '01450 Systems/00100 Menu/',
  '01450 Systems/00101 Dex/',
  '01450 Systems/00102 Party/',
  '01450 Systems/00103 Bag/',
  '01450 Systems/00104 Trainer/',
  '01450 Systems/00105 Options/',
  '01450 Systems/00106 Save Load/',
  '01450 Systems/00200 Storage/',
  '01450 Systems/00201 Daycare/',
  '01450 Systems/00202 Environment/',
  '01450 Systems/00203 Shop/',
  '01450 Systems/00204 Nuzlocke/',
  '01450 Systems/00205 Input/',
  '01450 Systems/00206 TownMap/',
  '01450 Systems/00207 Shortcut/',
  '01450 Systems/00300 Hall of fame/',
  '01450 Systems/00301 MoveTeaching/',
  '01450 Systems/00302 MoveReminder/',
  '01450 Systems/00303 Evolve/',
  '01450 Systems/00400 RSE Clock/',
  '01450 Systems/08000 Quest/',
  '01450 Systems/08001 Mining Game/',
  '01450 Systems/09000 GTS/',
  '01450 Systems/09000 Games/',
  '01450 Systems/10000 Movie/',
  '01450 Systems/99990 Global Systems/',
  '01450 Systems/99991 Wild/',
  '01500 Yuki/',
  '01600 Alpha 25 Battle Engine/00001 Battle_Scene/',
  '01600 Alpha 25 Battle Engine/00002 Battle_Visual/',
  '01600 Alpha 25 Battle Engine/00100 PokemonBattler/',
  '01600 Alpha 25 Battle Engine/00200 Battle_Logic/',
  '01600 Alpha 25 Battle Engine/03000 Actions/',
  '01600 Alpha 25 Battle Engine/04000 Effects/00001 Mechanics/',
  '01600 Alpha 25 Battle Engine/04000 Effects/00500 Move Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/00600 Status Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/00700 Ability Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/00800 Item Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/00900 O-Power Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/01000 Trainer Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/01100 Weather Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/01200 Field Terrain Effects/',
  '01600 Alpha 25 Battle Engine/04000 Effects/',
  '01600 Alpha 25 Battle Engine/04150 Battle_Move/00001 Mechanics/',
  '01600 Alpha 25 Battle Engine/04150 Battle_Move/00010 Definitions/',
  '01600 Alpha 25 Battle Engine/04150 Battle_Move/',
  '01600 Alpha 25 Battle Engine/05000 MoveAnimation/',
  '01600 Alpha 25 Battle Engine/08000 Battle_AI/00001 MoveHeuristic/',
  '01600 Alpha 25 Battle Engine/08000 Battle_AI/',
  '01600 Alpha 25 Battle Engine/99999 Pokemon_Script_Project/',
  '02000 Nuri Yuri/',
  '99999 Scripts_a_haute_dependences/'
]

def combine_scripts
  index = File.readlines('scripts/script_index.txt').map { |l| l.strip.sub('pokemonsdk/scripts/', '') }
  groups = index.group_by { |l| SCRIPT_GROUPS.find { |g| l.start_with?(g) } || '00000_a_root' }
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
  IO.copy_stream('LiteRGSS.rb.yard.rb', File.join(RELEASE_FOLDER, 'LiteRGSS.rb.yard.rb'))
end

unless $skipping_yard_doc
  move_documentation_files
  Dir.chdir(RELEASE_FOLDER) do
    system('yard doc')
  end
end