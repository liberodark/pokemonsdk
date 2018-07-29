#encoding: utf-8

#noyard
# Module that holds every UI class
module UI
  # Class that describe a percentage of something
  class Percent
    # Value of the percentage
    # @return [Numeric]
    attr_reader :value
    # Percentage of what
    # @return [Symbol]
    attr_accessor :what
    # Create a new percentage
    # @param value [Numeric] the percentage value
    # @param what [Symbol] of what the percentage is
    def initialize(value, what = :parent)
      self.value = value
      @what = what
    end
    # Chage the value (conversion if not Numeric)
    # @param value [Numeric] the percentage value
    def value=(value)
      @value = value.is_a?(Numeric) ? value : value.to_i
    end
    # 25% parent
    Parent_25 = self.new(25)
    # 33% parent
    Parent_33 = self.new(33)
    # 50% parent
    Parent_50 = self.new(50)
    # 66% parent
    Parent_66 = self.new(66)
    # 75% parent
    Parent_75 = self.new(75)
    # 100% parent
    Parent_100 = self.new(100)
    # 25% window
    Window_25 = self.new(25, :window)
    # 33% window
    Window_33 = self.new(33, :window)
    # 50% window
    Window_50 = self.new(50, :window)
    # 66% window
    Window_66 = self.new(66, :window)
    # 75% window
    Window_75 = self.new(75, :window)
    # 100% window
    Window_100 = self.new(100, :window)
  end
  # Class that describe a box padding
  class Box
    # Top property
    # @return [Integer]
    attr_accessor :top
    # Bottom property
    # @return [Integer]
    attr_accessor :bottom
    # Left property
    # @return [Integer]
    attr_accessor :left
    # Right property
    # @return [Integer]
    attr_accessor :right
    # Creates a new Box
    # @param top [Integer] top
    # @param bottom [Integer] bottom
    # @param left [Integer] left
    # @param right [Integer] right
    def initialize(top = 0, bottom = 0, left = 0, right = 0)
      @top = top.to_i
      @bottom = bottom.to_i
      @left = left.to_i
      @right = right.to_i
    end
    # Sets the box propreties
    # @param top [Integer, nil] top
    # @param bottom [Integer, nil] bottom
    # @param left [Integer, nil] left
    # @param right [Integer, nil] right
    # @return [self]
    def set(top, bottom = nil, left = nil, right = nil)
      @top = top.to_i if top
      @bottom = bottom.to_i if bottom
      @left = left.to_i if left
      @right = right.to_i if right
    end
  end
  # Class that holds an UI element
  #
  # Properties of an element : 
  #  - has paddings : top, bottom, left, right
  #  - has sizes : width, height
  #  - has clientsizes : client_width, client_height (size on window)
  #  - has parent
  #  - has childs
  #  - has something to display (contents)
  class Element
    # Create a new element
    # @param parent [Element, nil] the parent element
    # @param width [Numeric, Percent] the width of the element
    # @param height [Numeric, Percent] the height of the element
    # @param padding [Box, nil] the padding of the element
    def initialize(parent = nil, width = 0, height = 0, padding = nil)
      @padding = padding ? padding : Box.new
      @width = width
      @height = height
      @parent = parent
    end
  end
end
