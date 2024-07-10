# Class that describe a collection of characters
class String
  # Convert numeric related chars of the string to corresponding chars in the Pokemon DS font family
  # @return [self]
  # @author Nuri Yuri
  def to_pokemon_number
    return self unless Configs.texts.fonts.supports_pokemon_number

    tr!('0123456789n/', '│┤╡╢╖╕╣║╗╝‰▓')
    return self
  end
end

# Binding class of Ruby
class Binding
  alias [] local_variable_get
  alias []= local_variable_set
end

# Kernel module of Ruby
module Kernel
  # Infer the object as the specified class (lint)
  # @return [self]
  def from(other)
    raise "Object of class #{other.class} cannot be casted as #{self}" unless other.is_a?(self)

    return other
  end
end
