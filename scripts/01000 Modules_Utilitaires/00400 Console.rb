#encoding: utf-8

# Ruby's Kernel module
module Kernel
  module_function
  # Debug print command, prints each args using puts
  # @param args [Array<Object>]
  def pc(*args)
    args.each { |arg| puts arg.to_s }
  end
  # Change the color of the text
  # @param code [Integer] code & 0xF0 define the background, code & 0x0F define the text color
  def cc(code)
    bg = (code & 0xF0) >> 4
    fg = code & 0x0F
    if(bg < 8)
      print "\e[4#{bg&0x7}m"
    else
      print "\e[10#{bg&0x7}m"
    end
    if(fg < 8)
      print "\e[3#{fg&0x7}m"
    else
      print "\e[9#{fg&0x7}m"
    end
  end
end
