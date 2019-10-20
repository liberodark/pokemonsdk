$RELEASE = File.exist?('Data/Scripts.dat')
$DEBUG = false if $RELEASE
class Object
  private

  if $DEBUG
    # Is the game in debug ?
    # @return [Boolean]
    def debug?
      true
    end
  else
    # Is the game in debug ?
    # @return [Boolean]
    def debug?
      false
    end
  end
end

# Prevent Ruby from displaying the messages
$DEBUG = false

# Add version utility
class Integer
  def to_str_version
    [self].pack('I>').unpack('C*').join('.').gsub(/^(0\.)+/, '')
  end
end

class String
  def to_int_version
    split('.').collect(&:to_i).pack('C*').rjust(4, "\x00").unpack1('I>')
  end
end
