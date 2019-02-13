$RELEASE = File.exist?('Data/Scripts.dat')
$DEBUG = false if $RELEASE
$TEST = $DEBUG
# Prevent Ruby from displaying the messages
$DEBUG = false
