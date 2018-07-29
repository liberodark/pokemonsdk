#encoding: utf-8

# Class that describe game variables
class Game_Variables < Array
  # default initialization of game variables
  def initialize
    if($data_system)
      super($data_system.variables.size,0)
    else
      super(200,0)
    end
  end

  unless false
    # Setter
    # @param index [Integer] the index of the variable in the Array
    # @param v [Integer] the new value of the variable
    # @raise [TypeError] when maker or script attempt to store inconsistent value in the game variables.
    def []=(index, v)
      unless v.is_a?(Integer)
        raise TypeError, "Unexpected #{v.class} value. $game_variables store numbers and nothing else, use $option to store anything else."
      else
        super(size, 0) while size < index
        super(index,v)
      end
    end
  end

  # Getter
  # @param index [Integer] the index of the variable
  # @note return 0 if the variable is outside of the array.
  def [](index)
    return 0 if size <= index
    super
  end
end
