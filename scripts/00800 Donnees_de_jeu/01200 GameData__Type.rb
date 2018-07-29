#encoding: utf-8

module GameData
  # Type data structure
  # @author Nuri Yuri
  class Type < Base
    # Name of the unknown type
    DefaultName = "???"
    # ID of the text that gives the type name
    # @return [Integer]
    attr_accessor :text_id
    # Result multiplier when a offensive type hit on this defensive type
    # @return [Array<Numeric>]
    attr_accessor :on_hit_tbl
    # Create a new Type
    # @param text_id [Integer] id of the type name text in the 3rd text file
    # @param on_hit_tbl [Array<Numeric>] table of multiplier when an offensive type hit this defensive type 
    def initialize(text_id, on_hit_tbl)
      #>Id du text à récuperer
      @text_id = text_id
      #>Table des multiplicateur quand il se fait touché par un type
      @on_hit_tbl = on_hit_tbl
    end
    # Return the name of the type
    # @return [String]
    def name
      return GameData::Text.get(3, @text_id) if @text_id>=0
      return DefaultName
    end
    # Return the damage multiplier
    # @param type_id [Integer] id of the offensive type
    # @return [Numeric]
    def hit_by(type_id)
      return @on_hit_tbl[type_id]
    end
  end
end
