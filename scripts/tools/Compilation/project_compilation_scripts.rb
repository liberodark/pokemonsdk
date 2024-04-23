module ProjectCompilation
  class ScriptCollector
    EXCLUDED_SCRIPTS = [
      'pokemonsdk/scripts/01500 Yuki/01200 Yuki__WorldMapEditor.rb',
      'pokemonsdk/scripts/01500 Yuki/02400 Yuki_Debug.rb',
      'pokemonsdk/scripts/01500 Yuki/02401 Yuki__Debug MainUI.rb',
      'pokemonsdk/scripts/01500 Yuki/02402 Debug_SystemTags.rb',
      'pokemonsdk/scripts/01500 Yuki/02403 Debug_Groups.rb',
      'pokemonsdk/scripts/00700 Ajout_PSDK/00200 Tester.rb',
      'pokemonsdk/scripts/00700 Ajout_PSDK/01700 Debugger.rb'
    ]
    VD_SCRIPT = 'Yuki__VD.rb'

    # @param script_class [Class<Script>]
    def initialize(script_class)
      @script_class = script_class
    end

    # @param paths [Array<String>]
    def collect_scripts(paths)
      scripts = collect_ruby_scripts(psdk_script_filenames, psdk_script_path)
      paths.each { |path| scripts.concat(collect_vscode_scripts(path)) }
      scripts.concat(collect_rmxp_script)

      vd_scripts = scripts.select { |script| script.filename.end_with?(VD_SCRIPT) }
      non_vd_scripts = scripts.reject { |script| script.filename.end_with?(VD_SCRIPT) }
      return vd_scripts.concat(non_vd_scripts)
    end

    private

    # @return [Array<Script>]
    def collect_rmxp_script
      ban1 = 'config'
      ban2 = 'boot'
      ban3 = '_'
      return load_data('Data/Scripts.rxdata').filter_map do |script|
        # @type [String]
        name = script[1].force_encoding(Encoding::UTF_8)
        next if name.downcase.start_with?(ban1, ban2, ban3)

        next @script_class.new(name, Zlib::Inflate.inflate(script[2]).force_encoding(Encoding::UTF_8))
      end
    end

    def psdk_script_path
      env_lookup = Dir.exist?('pokemonsdk') ? ['ALTERNATIVE_PATH'] : ['ALTERNATIVE_PATH', 'PSDK_BINARY_PATH']
      return env_lookup.map { |name| ENV[name] }.compact.first&.tr('\\', '/') || '.'
    end

    def psdk_script_filenames
      lines = File.readlines(File.join(psdk_script_path, 'pokemonsdk/scripts/script_index.txt')).map(&:chomp)
      EXCLUDED_SCRIPTS.each { |filename| lines.delete(filename) }
      return lines
    end

    # @param filenames [Array<String>]
    # @param path [String]
    # @return [Array<Script>]
    def collect_ruby_scripts(filenames, path)
      filenames.flat_map do |filename|
        script = File.read(File.join(path, filename.chomp))
        next process_bootloader(script, File.dirname(filename)) if Utils.script_bootloader?(script)

        next @script_class.new(filename, script)
      end
    end

    # Function that process a bootloader script
    # @param script [String]
    # @param dirname [String] relative directory of the bootloader script (to match require_relative)
    def process_bootloader(script, dirname)
      # @type [Array<String>]
      lines = script.split("\n").map(&:strip)
      return [] unless Utils.bootloader_condition_valid?(lines)

      scripts_to_load_lines = lines.select { |line| line.start_with?("require_relative '") && line.end_with?("'") && !line.include?('.rb') }
      return scripts_to_load_lines.map do |line|
        script_name = line.sub("require_relative '", '').sub("'", '.rb')
        filename = File.join(dirname, script_name)
        next @script_class.new(filename, File.read(filename))
      end
    end

    def folder_script_filenames(path)
      return Dir[File.join(path, '*.rb')].sort.filter_map do |filename|
        basename = File.basename(filename)
        next unless basename =~ /^[0-9]{5}[ _].*/

        next basename
      end
    end

    # @return [Array<Script>]
    def collect_vscode_scripts(path)
      folder_scripts = collect_ruby_scripts(folder_script_filenames(path), path)
      sub_folder_scripts = Dir[File.join(path, '*/')].grep(ScriptLoader::SCRIPT_FOLDER_REG).sort.flat_map do |pathname|
        collect_vscode_scripts(pathname)
      end
      return folder_scripts.concat(sub_folder_scripts)
    end

    class Script
      # @return [String]
      attr_reader :filename

      def initialize(filename, content)
        @filename = filename
        @content = content
      end

      def compile
        return Utils.compile(@filename, @content)
      end
    end

    class ScriptSaver
      # @param scripts [Array<Script>]
      def initialize(scripts)
        @scripts = scripts
      end

      def save(filename)
        File.binwrite(filename, Zlib::Deflate.deflate(Marshal.dump(compile_all_scripts)))
        puts 'Script saved...'
      end

      def compile_all_scripts
       return  @scripts.map do |script|
          puts "Compiling #{script.filename}"
          script.compile
        end
      end
    end
  end
end
