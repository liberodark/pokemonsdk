# Ruby Object class
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
