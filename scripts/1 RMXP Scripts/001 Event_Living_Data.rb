# Class describing game switches (events)
class Game_Switches < Array
  # Default initialization of game switches
  def initialize
    if $data_system
      super($data_system.switches.size, false)
    else
      super(200, false)
    end
  end

  # Converting game switches to bits
  def _dump(_level = 0)
    gsize = (size / 8 + 1)
    str = "\x00" * gsize
    gsize.times do |i|
      index = i * 8
      number = self[index] ? 1 : 0
      number |= 2 if self[index + 1]
      number |= 4 if self[index + 2]
      number |= 8 if self[index + 3]
      number |= 16 if self[index + 4]
      number |= 32 if self[index + 5]
      number |= 64 if self[index + 6]
      number |= 128 if self[index + 7]
      str.setbyte(i, number)
    end
    return str
  end

  # Loading game switches from the save file
  def self._load(args)
    var = Game_Switches.new
    args.size.times do |i|
      index = i * 8
      number = args.getbyte(i)
      var[index] = (number[0] == 1)
      var[index + 1] = (number[1] == 1)
      var[index + 2] = (number[2] == 1)
      var[index + 3] = (number[3] == 1)
      var[index + 4] = (number[4] == 1)
      var[index + 5] = (number[5] == 1)
      var[index + 6] = (number[6] == 1)
      var[index + 7] = (number[7] == 1)
    end
    return var
  end
end

# Class that describe game variables
class Game_Variables < Array
  # default initialization of game variables
  def initialize
    if $data_system
      super($data_system.variables.size, 0)
    else
      super(200, 0)
    end
  end

  # Getter
  # @param index [Integer] the index of the variable
  # @note return 0 if the variable is outside of the array.
  def [](index)
    return 0 if size <= index

    super(index)
  end

  # Setter
  # @param index [Integer] the index of the variable in the Array
  # @param value [Integer] the new value of the variable
  def []=(index, value)
    unless value.is_a?(Integer)
      raise TypeError, "Unexpected #{value.class} value. $game_variables store numbers and nothing else, use $option to store anything else."
    end

    super(size, 0) while size < index
    super(index, value)
  end
end

# Describe switches that are related to a specific event
# @author Enterbrain
class Game_SelfSwitches
  # Default initialization
  def initialize
    @data = {}
  end

  # Get the state of a self switch
  # @param key [Array] the key that identify the self switch
  # @return [Boolean]
  def [](key)
    return @data[key]
  end

  # Set the state of a self switch
  # @param key [Array] the key that identify the self switch
  # @param value [Boolean] the new value of the self switch
  def []=(key, value)
    @data[key] = value
  end
end

# Collection of Game_Actor
class Game_Actors
  # Default initialization
  def initialize
    @data = []
  end

  # Fetch Game_Actor
  # @param actor_id [Integer] id of the Game_Actor in the database
  # @return [Game_Actor, nil]
  def [](actor_id)
    return nil if actor_id > 999 || $data_actors[actor_id].nil?

    @data[actor_id] ||= Game_Actor.new(actor_id)
    return @data[actor_id]
  end
end
