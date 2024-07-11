# Note before using that script:
# You must be allowed to push to development and release
# You should have run `ruby make_release.rb` before
RELEASE_FOLDER = '.release'
$dry_run = ARGV.include?('dry')
Dir.chdir('..')

def mkdir!(path)
  return if Dir.exist?(path)
  total_path = ''
  path.split(%r{[/\\]}).each do |dirname|
    next if dirname.empty?

    total_path << dirname
    Dir.mkdir(total_path) unless Dir.exist?(total_path)
    total_path << '/'
  end
end

# Go back to development
system('git clean -df')
system('git reset --hard HEAD')
system('git checkout development')
system('git pull')

# Copy all the file that matter for the release
all_files_to_copy = ['scripts/ScriptLoad.rb', 'scripts/ScriptMonitor.rb', *Dir['scripts/tools/**/*.rb']]
all_files_to_copy.each do |f|
  target_filename = File.join(RELEASE_FOLDER, f)
  mkdir!(File.dirname(target_filename))
  IO.copy_stream(f, target_filename)
end

# Update version
version = File.read('version.txt').to_i
version += (ARGV.include?('bump') ? 256 - (version % 256) : 1)
version_text = [version].pack('I>').unpack('C*').join('.').gsub(/^(0\.)+/, '')

unless ARGV.include?('skip_develop')
  File.write('version.txt', version.to_s)

  # Commit new version
  system('git add version.txt')
  system("git commit -m \"PSDK #{version_text}\"")
  system('git push') unless $dry_run
end

# Go to release and process to release the new version
system('git checkout release')
system('git pull')

# Write new version again
File.write('version.txt', version.to_s)

# Delete all left over scripts
Dir['scripts/**/*.rb'].each { |f| File.delete(f) }
system('git clean -df')

# Copy back all scripts to copy
Dir[File.join(RELEASE_FOLDER, 'scripts/**/*.rb')].each do |f|
  target_filename = f.sub("#{RELEASE_FOLDER}/", '')
  mkdir!(File.dirname(target_filename))
  IO.copy_stream(f, target_filename)
end

# Copy all the docs file so user can just use those instead of the full ruby scripts
Dir[File.join(RELEASE_FOLDER, 'docs/**/*.rb')].each do |f|
  target_filename = f.sub("#{RELEASE_FOLDER}/", '')
  mkdir!(File.dirname(target_filename))
  IO.copy_stream(f, target_filename)
end

# Copy the LiteRGSS.yard.rb file
IO.copy_stream(File.join(RELEASE_FOLDER, 'LiteRGSS.rb.yard.rb'), File.join('scripts', 'LiteRGSS.rb'))
# Copy the script index file
IO.copy_stream(File.join(RELEASE_FOLDER, 'scripts','script_index.txt'), File.join('scripts', 'script_index.txt'))

# Push the new release
system('git add .')
system("git commit -m \"Release #{version_text}\"")
system("git tag -l \".#{version_text}\"") unless $dry_run
system('git push') unless $dry_run
