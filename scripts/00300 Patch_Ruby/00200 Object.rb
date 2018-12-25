#encoding: utf-8

# Base classe of roughly everything.
class Object
  # Method that sets the properties of the object to a value using a Hash of property_name => value
  # @param properties [Hash{Symbol => Object}] dict of properties with their new value
  # @return [self]
  # @author Nuri Yuri
  def apply_property(properties)
    common_properties = CommonProperties
    i = nil
    sym = nil
    properties.each do |i|
      sym = common_properties[i[0]]
      self.send(sym, i[1]) if sym
    end
    return self
  end
  # Constant that contains common properties used by #apply_properties
  CommonProperties = {
    :x => :x=,
    :y => :y=,
    :z => :z=,
    :ox => :ox=,
    :oy => :oy=,
    :zoom_x => :zoom_x=,
    :zoom_y => :zoom_y=,
    :angle => :angle=,
    :opacity => :opacity=,
    :blend_type => :blend_type=,
    :mirror => :mirror=,
    :visible => :visible=,
    :zoom => :zoom=
  }
end
