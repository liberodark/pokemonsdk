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
