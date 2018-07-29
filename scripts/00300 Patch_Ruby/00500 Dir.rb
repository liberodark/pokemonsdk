#encoding: utf-8

# Class that helps doing stuff related to Directories
class Dir
  # Make a new dir by following the path
  # @param path [String] the new path to create
  # @example Dir.mkdir!("a/b/c") will create a, a/b and a/b/c.
  def self.mkdir!(path)
    ori = Dir.pwd
    path.split(/[\/\\]/).each do |dirname|
      next if dirname.size == 0
      Dir.mkdir(dirname) unless Dir.exist?(dirname)
      Dir.chdir(dirname)
    end
    Dir.chdir(ori)
  end
end
