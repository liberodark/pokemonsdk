module PFM
  # The InGame skill/move information of a Pokemon
  # @author Nuri Yuri
  class Skill
    # The maximum number of PP the skill has
    # @return [Integer]
    attr_accessor :ppmax
    # The current number of PP the skill has
    # @return [Integer]
    attr_reader :pp
    # ID of the skill in the Database
    # @return [Integer]
    attr_reader :id

    # Create a new Skill information
    # @param db_symbol [Symbol] db_symbol of the skill/move in the database
    def initialize(db_symbol)
      data = data_move(db_symbol)
      @id = data.id
      @db_symbol = data.db_symbol
      if @id == 0
        @ppmax = 0
        @pp = 0
        return
      end
      @ppmax = data.pp
      @pp = @ppmax
    end

    # Return the actual data of the move
    # @return [Studio::Move]
    def data
      return data_move(@db_symbol || @id || :__undef__)
    end

    # Return the db_symbol of the skill
    # @return [Symbol]
    def db_symbol
      return @db_symbol ||= data.db_symbol
    end

    # Return the name of the skill
    # @return [String]
    def name
      return data.name
    end

    # Return the symbol of the method to call in BattleEngine
    # @return [Symbol]
    def symbol
      return data.be_method
    end

    # Return the text of the power of the skill
    # @return [String]
    def power_text
      power = base_power
      return text_get(11, 12) if power == 0

      return power.to_s
    end

    # Return the text of the PP of the skill
    # @return [String]
    def pp_text
      "#{@pp} / #{@ppmax}"
    end

    # Return the base power (Data power) of the skill
    # @return [Integer]
    def base_power
      return data.power
    end
    alias power base_power

    # Return the actual type ID of the skill
    # @return [Integer]
    def type
      return data_type(data.type).id
    end

    # Return the actual accuracy of the skill
    # @return [Integer]
    def accuracy
      return data.accuracy
    end

    # Return the accuracy text of the skill
    # @return [String]
    def accuracy_text
      acc = data.accuracy
      return text_get(11, 12) if acc == 0

      return acc.to_s
    end

    # Return the skill description
    # @return [String]
    def description
      return text_get(7, @id || 0) # GameData::Skill.descr(@id)
    end

    # Return the ID of the common event to call on Map use
    # @return [Integer]
    def map_use
      return data.map_use
    end

    # Is the skill a specific type ?
    # @param type_id [Integer] ID of the type
    def type?(type_id)
      return type == type_id
    end

    # Change the PP
    # @param v [Integer] the new pp value
    def pp=(v)
      @pp = v.clamp(0, @ppmax)
    end

    # Get the ATK class for the UI
    # @return [Integer]
    def atk_class
      return 2 if data.category == :special
      return 3 if data.category == :status

      return 1
    end
  end
end
