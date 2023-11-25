module ProjectCompilation
  ScriptLoader.load_tool('Compilation/project_compilation_utils')
  ScriptLoader.load_tool('Compilation/project_compilation_data_builder')
  ScriptLoader.load_tool('Compilation/project_compilation_graphics_builder')
  ScriptLoader.load_tool('Compilation/project_compilation_scripts')
  RELEASE_PATH = 'Release'
  GRAPHICS_FILES = {}
  NO_RECURSIVE_PATH = []
  DATA_FILES = {}
  GAME_RB_SCRIPTS = %w[
    GameLoader/z_close_stdin.rb
    PARGV.rb
    GameLoader/1_setupConstantAndLoadPath.rb
    GameLoader/2_displayException.rb
    GameLoader/3_load_extensions.rb
    GameLoader/31_ruby_dependencies.rb
    GameLoader/32_console_compiled.rb
    GameLoader/41_load_data_compiled.rb
    GameLoader/Z_main.rb
    GameLoader/51_load_game_compiled.rb
    GameLoader/60_start_game.rb
  ]

  module_function

  def start
    make_release_path
    start_script_compilation
    make_game_rb
    make_graphic_resources unless ARGV.include?('skip_graphics')
    make_data unless ARGV.include?('skip_data')
    copy_lib unless ARGV.include?('skip_lib')
    copy_audio unless ARGV.include?('skip_audio')
    copy_binaries unless ARGV.include?('skip_binary')
  end

  def start_script_compilation
    collector = ScriptCollector.new(ScriptCollector::Script)
    saver = ScriptCollector::ScriptSaver.new(collector.collect_scripts([ScriptLoader::PROJECT_SCRIPT_PATH]))
    saver.save(File.join(RELEASE_PATH, 'Data', 'Scripts.dat'))
  end

  def collect_game_rb_scripts
    # Compile real Game.rb
    game_script = GAME_RB_SCRIPTS.collect { |filename| File.read("#{ScriptLoader::VSCODE_SCRIPT_PATH}/tools/#{filename}") }.join("\r\n\r\n")
    # Make the game not depending on a specific file for the PSDK version
    game_script.sub!('PSDK_VERSION = File.read("#{PSDK_PATH}/version.txt").to_i', "PSDK_VERSION = #{PSDK_VERSION}")
    return game_script
  end

  def make_game_rb
    File.binwrite(File.join(RELEASE_PATH, 'Game.yarb'), Utils.compile('Game/Boot.rb', collect_game_rb_scripts))
    # Write Game.rb
    File.write(File.join(RELEASE_PATH, 'Game.rb'), <<~'SCRIPT' )
    RubyVM::InstructionSequence.load_from_binary(File.binread('Game.yarb')).eval
    SCRIPT
  end

  def make_graphic_resources
    release_path = File.join(RELEASE_PATH, 'pokemonsdk', 'master')
    psdk_path = File.join(PSDK_PATH, 'master')
    GRAPHICS_FILES.each do |cache_name, path|
      GraphicsBuilder.start("#{psdk_path}/#{cache_name}", "#{release_path}/#{cache_name}", path, NO_RECURSIVE_PATH.include?(cache_name))
    end
    # Copy Shaders
    Dir['graphics/shaders/*.*'].each { |filename| File.copy_stream(filename, File.join(RELEASE_PATH, filename)) }
    # Copy Fonts
    Dir['Fonts/*.*'].each { |filename| File.copy_stream(filename, File.join(RELEASE_PATH, filename)) }
  end

  def make_data
    DataBuilder.start(RELEASE_PATH)
  end

  def make_release_path
    Dir.mkdir!(File.join(RELEASE_PATH, 'Data'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'bgm'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'bgs'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'se', 'cries'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'se', 'voltorbflip'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'se', 'mining_game'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'se', 'moves'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'me'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'audio', 'particles'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'graphics', 'shaders'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'pokemonsdk', 'master'))
    File.copy_stream("#{ScriptLoader::VSCODE_SCRIPT_PATH.split('/')[0..-2].join('/')}/version.txt", File.join(RELEASE_PATH, 'pokemonsdk/version.txt'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'Fonts'))
    Dir.mkdir!(File.join(RELEASE_PATH, 'Saves'))
    return if PSDK_PLATFORM != :windows

    Dir.mkdir!(File.join(RELEASE_PATH, 'ruby_builtin_dlls'))
    lib_dirs = Utils.lib_files_to_copy.collect { |filename| File.dirname(filename) }.uniq
    lib_dirs.each do |dirname|
      Dir.mkdir!(File.join(RELEASE_PATH, dirname))
    end
  end

  def copy_lib
    return if PSDK_PLATFORM == :android
    puts 'Copying Ruby Library (add skip_lib to arguments to skip this part)'
    if PSDK_PLATFORM == :windows
      Utils.lib_files_to_copy.each do |filename|
        IO.copy_stream("#{ENV['PSDK_BINARY_PATH']}#{filename}".tr('\\', '/'), File.join(RELEASE_PATH, filename))
      end
    else
      # Note: we need the setup.sh and additional files to make it run
      # Note: -r = recursive -n = skip existing files
      system("cp -r -n \"#{PSDK_LIB_PATH}/..\" \"#{RELEASE_PATH}/ruby-dist\"")
    end
  end

  def copy_audio
    puts 'Copying Audios (add skip_audio to argument to skip this part)'
    Dir['audio/**/*'].each do |filename|
      next if File.directory?(filename)
      IO.copy_stream(filename, File.join(RELEASE_PATH, filename).downcase)
    end
  end

  def copy_binaries
    return make_game_sh if PSDK_PLATFORM != :windows

    puts 'Copying binaries'
    Dir["#{ENV['PSDK_BINARY_PATH']&.tr('\\', '/')}ruby_builtin_dlls/**"].each do |filename|
      next if File.directory?(filename)

      target_filename = ENV['PSDK_BINARY_PATH'] ? filename.sub(ENV['PSDK_BINARY_PATH'].tr('\\', '/'), '') : filename
      IO.copy_stream(filename, File.join(RELEASE_PATH, target_filename))
    end
    # Copy EXE
    IO.copy_stream('Gamew.exe', File.join(RELEASE_PATH, 'Game.exe'))
    %w[
      ruby.exe
      rubyw.exe
      msvcrt-ruby300.dll
    ].each { |filename| IO.copy_stream("#{ENV['PSDK_BINARY_PATH']&.tr('\\', '/')}#{filename}", File.join(RELEASE_PATH, filename)) }
  end

  def make_game_sh
    return if PSDK_PLATFORM == :android

    file_content = <<~EOGAMESH
      #!/bin/bash
      cd ruby-dist
      source setup.sh
      cd ..
      ruby Game.rb "$@"
    EOGAMESH
    path = File.join(RELEASE_PATH, 'Game.sh')
    File.write(path, file_content) if !File.exist?(path) || File.read(path) != file_content
    system("chmod u+x \"#{path}\"")
  end

  def add_graphics_folder(vd_filename, path_from_graphics, recursive = true)
    vd_filename = vd_filename.to_s.downcase
    # Add vd_filename => graphics folder association
    GRAPHICS_FILES[vd_filename] = "graphics/#{path_from_graphics}".downcase
    # Tell if the path is recursive or not (we include the subfolder or not)
    if recursive
      NO_RECURSIVE_PATH.delete(vd_filename)
    else
      NO_RECURSIVE_PATH << vd_filename
    end
  end

  add_graphics_folder('animation', 'animations')
  add_graphics_folder('autotile', 'autotiles')
  add_graphics_folder('ball', 'ball')
  add_graphics_folder('battleback', 'battlebacks')
  add_graphics_folder('battler', 'battlers')
  add_graphics_folder('character', 'characters')
  add_graphics_folder('fog', 'fogs')
  add_graphics_folder('icon', 'icons')
  add_graphics_folder('interface', 'interface')
  add_graphics_folder('panorama', 'panoramas')
  add_graphics_folder('particle', 'particles')
  add_graphics_folder('pc', 'pc')
  add_graphics_folder('picture', 'pictures')
  add_graphics_folder('pokedex', 'pokedex', false)
  add_graphics_folder('title', 'titles')
  add_graphics_folder('tileset', 'tilesets')
  add_graphics_folder('transition', 'transitions')
  add_graphics_folder('windowskin', 'windowskins')
  add_graphics_folder('foot_print', 'pokedex/footprints')
  add_graphics_folder('b_icon', 'pokedex/pokeicon')
  add_graphics_folder('poke_front', 'pokedex/pokefront')
  add_graphics_folder('poke_front_s', 'pokedex/pokefrontshiny')
  add_graphics_folder('poke_back', 'pokedex/pokeback')
  add_graphics_folder('poke_back_s', 'pokedex/pokebackshiny')

  def delete_graphics_folder(vd_filename)
    vd_filename = vd_filename.to_s.downcase
    GRAPHICS_FILES.delete(vd_filename)
    NO_RECURSIVE_PATH.delete(vd_filename)
  end

  def add_data_files(id, &file_list_getter)
    DATA_FILES[id] = file_list_getter
  end

  add_data_files(0) { get_data_files.last }
  add_data_files(1) { get_data_files.first }
  add_data_files(2) { Dir['Data/Text/Dialogs/*.dat'] }
  add_data_files(3) { ['Data/Studio/psdk.dat', 'Data/PSDK/Maplinks.rxdata', 'Data/PSDK/SystemTags.rxdata'] }
  add_data_files(4) { Dir['Data/Animations/*.dat'] }
  add_data_files(5) { Dir['Data/Events/Battle/*.yarbc'] }

  def delete_data_files(id)
    DATA_FILES.delete(id)
  end
end

rgss_main {}

ProjectCompilation.start
