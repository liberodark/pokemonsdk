#encoding: utf-8

# Class describing game switches (events)
class Game_Switches < Array
  # Default initialization of game switches
  def initialize
    if($data_system)
      super($data_system.switches.size,false)
    else
      super(200,false)
    end
  end
  # Converting game switches to bits
  def _dump(level=0)
    gsize = (self.size / 8 + 1)
    str = "\x00"*gsize
    gsize.times do |i|
      index = i * 8
      number = self[index] ? 1 : 0
      number |= 2 if self[index+1]
      number |= 4 if self[index+2]
      number |= 8 if self[index+3]
      number |= 16 if self[index+4]
      number |= 32 if self[index+5]
      number |= 64 if self[index+6]
      number |= 128 if self[index+7]
      str.setbyte(i,number)
    end
    return str
  end
  # Loading game switches from the save file
  def self._load(args)
    var=Game_Switches.new
    args.size.times do |i|
      index=i*8
      number=args.getbyte(i)
      var[index]=(number[0]==1)
      var[index+1]=(number[1]==1)
      var[index+2]=(number[2]==1)
      var[index+3]=(number[3]==1)
      var[index+4]=(number[4]==1)
      var[index+5]=(number[5]==1)
      var[index+6]=(number[6]==1)
      var[index+7]=(number[7]==1)
    end
    return var
  end
end
