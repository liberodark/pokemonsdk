#encoding: utf-8

# The virtual directory reader
class Yuki::VD
  @@opened_files = []
  # The max size of the file that can be loaded in memory
  MaxSize = 5242880
  # Create a new Yuki::VD file or load it
  # @param filename [String] name of the Yuki::VD file
  # @param mode [:read, :write, :update] if we read or write the virtual directory
  # @param encrypt [Integer] a key that allow Virtual directory encryption
  def initialize(filename, mode, encrypt = 0)
    return if mode == :empty
    @encrypt = true if (encrypt ^ 0xFEAAE) == 0
    @filename = filename
    if(mode == :read)
      if(@@opened_files.include?(filename.split("/")[-1]))
        raise RuntimeError, nil.to_s
      end
      @@opened_files << filename.split("/")[-1]
      unless File.exists?(filename)
        @hash = {}
        @file = filename
        return
      end
      @file = File.new(filename, "rb")
      pos = @file.pos = @file.read(4).unpack("L").first
      if @encrypt
        data = @file.read(File.size(filename) - @file.pos)
        @hash = Marshal.load(load_data(data))
      else
        @hash = Marshal.load(@file)
      end
      load_whole_file(pos) if(pos < MaxSize)
    elsif(mode == :update)
      data = File.open(filename, "rb") do |f| f.read(f.size) end
      pos = data.unpack("L").first
      File.rename(filename, filename + '.bak')
      @file = File.new(filename, "wb+")
      @file << data
      data = nil
      @file.pos = pos
      @hash = Marshal.load(@file)
      @file.pos = pos
    else
      @file = File.new(filename, "wb")
      @file.pos = 4
      @hash = {}
    end
    @mode = mode
  end
  # The empty VD file
  @@Empty = self.new(nil, :empty)
  # Read a file data from the VD
  # @param filename [String] the file we want to read its data
  # @return [String] the data of the file
  def read_data(filename)
    raise RuntimeError, nil.to_s unless @file
    pos = @hash[filename]
    return nil unless pos
    @file.pos = pos
    size = @file.read(4).unpack("L")[0]
    data = @file.read(size)
    if(@encrypt)
      #data = load_data(data)[0, data.size - 4]
    end
    return data
  end
  # Test if a file exists in the VD
  # @param filename [String]
  # @return [Boolean]
  def exists?(filename)
    @hash[filename] != nil
  end
  # Write a file with its data in the VD
  # @param filename [String] the file name
  # @param data [String] the data of the file
  def write_data(filename, data)
    if @encrypt
      #data = save_data(data, [rand(2**32) ^ 0x541D2EF2].pack("L"))
    end
    @hash[filename] = @file.pos
    @file.write([data.bytesize].pack("I"))
    @file.write(data)
  end
  # Add a file to the Yuki::VD
  # @param filename [String] the file name
  # @param ext_name [String, nil] the file extension
  def add_file(filename, ext_name = nil)
    sub_filename = ext_name ? "#{filename}.#{ext_name}" : filename
    data = File.open(sub_filename, "rb") do |f| f.read(f.size) end
    write_data(filename, data)
  end
  # Get all the filename
  # @return [Array<String>]
  def get_filenames
    @hash.keys
  end
  # Load the VD in the memory
  # @param size [Integer] size of the VD memory
  def load_whole_file(size)
    @file.pos = 0
    data = @file.read(size)
    @file.close
    @file = data
    def data.pos=(v)
      @pos = v
    end
    def data.read(size)
      content = Marshal.load(Marshal.dump(self[@pos, size]))
      @pos += size
      content
    end
    def data.close
    end
    data.pos = 0
  end
  private :load_whole_file
  # Close the VD
  def close
    raise RuntimeError, nil.to_s unless @file
    if(@mode == :read)
      @file.close
      @@opened_files.delete(@filename.split("/")[-1])
    else
      pos = [@file.pos].pack("I")
      if @encrypt
        data = Marshal.dump(@hash)#save_data(Marshal.dump(@hash), [rand(2**32) ^ 0x10DE33FC].pack("L"))
      else
        data = Marshal.dump(@hash)
      end
      @file.write(data)
      @file.pos = 0
      @file.write(pos)
      @file.close
    end
    @file = nil
  end
end
