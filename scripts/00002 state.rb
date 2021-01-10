class Object
  private

  # Is the game in debug ?
  # @return [Boolean]
  def debug?
    PSDK_CONFIG.debug?
  end
end

# Prevent Ruby from displaying the messages
$DEBUG = false

# Add version utility
class Integer
  def to_str_version
    # [self].pack('I>').unpack('C*').join('.').gsub(/^(0\.)+/, '')
    arr = [self].pack('I>').unpack('C*')
    if arr[2] == 24 && arr[3] >= 128
      arr[2] = 25
      arr[3] -= 256
    end
    return arr.join('.').gsub(/^(0\.)+/, '')
  end
end

class String
  def to_int_version
    split('.').collect(&:to_i).pack('C*').rjust(4, "\x00").unpack1('I>')
  end
end
