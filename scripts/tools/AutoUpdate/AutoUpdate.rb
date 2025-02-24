# Module responsive of helping auto updates on maker's projects
#
# How to load: ScriptLoader.load_tool('AutoUpdate/AutoUpdate')
#
# How to add a new file
# 1. load the AutoUpdate module
# 2. Run as much as you need AutoUpdate.add_known_file(filename)
# 3. Run AutoUpdate.save_known_files
#
# How to update all local files: run psdk --util=auto_update
#
# How to refresh all repository files: run psdk --util=auto_update_refresh
module AutoUpdate
  require 'digest/md5'

  # Name of the directory holding all the files to update
  AUTO_UPDATE_DIR = File.dirname(__FILE__)
  # Name of the file holding all the auto update data
  AUTO_UPDATE_FILENAME = File.join(AUTO_UPDATE_DIR, 'AutoUpdateFiles.txt')
  # Signature of a deleted file
  DELETED_SIGNATURE = 'deleted'

  module_function

  # load all the known repository files
  # @return [Hash{String => Array<String> }]
  def load_repository_files
    return {} unless File.exist?(AUTO_UPDATE_FILENAME)

    File.readlines(AUTO_UPDATE_FILENAME, chomp: true).map do |file_data|
      filename, *known_hashes = file_data.split(':')
      next [filename, known_hashes]
    end.to_h
  end

  def add_known_file(filename)
    @repository_files ||= load_repository_files
    entry_name = filename.sub(File.expand_path('.') + '/', '')
    @repository_files[entry_name] ||= [Digest::MD5.hexdigest(File.binread(entry_name))]
    target_filename = File.join(AUTO_UPDATE_DIR, filename)
    make_dir(filename) unless File.exist?(target_filename)
    IO.copy_stream(filename, target_filename)
  end

  def refresh_known_files
    @repository_files ||= load_repository_files
    @repository_files.each do |filename, known_hashes|
      if known_hashes.last != DELETED_SIGNATURE && !File.exist?(filename)
        known_hashes << DELETED_SIGNATURE
        next File.delete(File.join(AUTO_UPDATE_DIR, filename))
      end
      next unless File.exist?(filename)

      new_hash = Digest::MD5.hexdigest(File.binread(filename))
      next if known_hashes.last == new_hash

      puts "Refreshing #{filename}"
      known_hashes << new_hash
      target_filename = File.join(AUTO_UPDATE_DIR, filename)
      make_dir(filename) unless File.exist?(target_filename)
      IO.copy_stream(filename, target_filename)
    end
    save_known_files
  end

  def update_maker_files
    @repository_files ||= load_repository_files
    @repository_files.each do |filename, known_hashes|
      next if known_hashes.last == DELETED_SIGNATURE
      next update_single_file(filename) unless File.exist?(filename)

      hash = Digest::MD5.hexdigest(File.binread(filename))
      next update_single_file(filename) if known_hashes.include?(hash) && known_hashes.last != hash

      puts "Unknown hash #{hash} for #{filename}" if known_hashes.last != hash
    end
  end

  def update_single_file(filename)
    puts "Updating: #{filename}..."
    source_filename = File.join(AUTO_UPDATE_DIR, filename)
    IO.copy_stream(source_filename, filename)
  end

  def save_known_files
    @repository_files ||= load_repository_files
    File.write(AUTO_UPDATE_FILENAME, @repository_files.map { |k, v| "#{k}:#{v.join(':')}" }.join("\n"))
  end

  def make_dir(filename)
    Dir.chdir(AUTO_UPDATE_DIR) do
      Dir.mkdir!(File.dirname(filename))
    end
  end
end
