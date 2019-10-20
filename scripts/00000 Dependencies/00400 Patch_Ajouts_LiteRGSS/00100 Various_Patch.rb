# Store the RGSS Main entry function
def rgss_main
  $GAME_LOOP = proc do
    yield
  rescue StandardError => e
    if e.class.to_s == 'Reset'
      $scene.main if $scene.is_a?(Yuki::SoftReset)
      retry
    end
  end
end

# Load data from a file and convert its string to UTF-8
# @param filename [String] name of the file where to load the data
# @return [Object]
def load_data_utf8(filename)
  unless $RELEASE && filename.start_with?('Data/')
    File.open(filename) do |f|
      return Marshal.load(f, proc { |o| o.class == String ? o.force_encoding(Encoding::UTF_8) : o })
    end
  end
  return load_data(filename, true)
end

# Force string to UTF-8
# @param str [String]
# @return [String] str with UTF-8 encoding
def _utf8(str)
  return str.force_encoding(Encoding::UTF_8)
end
