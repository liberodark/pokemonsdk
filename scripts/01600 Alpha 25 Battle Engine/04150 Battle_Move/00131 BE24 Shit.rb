module Battle
  class Move
    def power
      return @power2 || base_power
    end

    attr_accessor :power2

    alias accuracy_data accuracy
    def accuracy
      @accuracy2 || accuracy_data
    end

    attr_accessor :accuracy2

    def type
      return @type2 || data.type
    end

    attr_accessor :type2

    # Change the skill information (copy, sketch, Z-move etc...)
    # @param id [Integer] ID of the skill in the database
    # @param pp [Integer, nil] the number of pp of the skill, nil = no change about PPs
    # @param sketch [Boolean] if the skill informations are definitely changed
    def switch(id, pp = 10, sketch = false)
      return initialize(id) if sketch
  
      data = GameData::Skill[id]
      @id_bis = @id
      @pp_bis = @pp if pp
      @pp_max_bis = @ppmax
      @id = data.id
      if @id == 0
        @pp = @ppmax = 0
        return
      end
  
      if pp
        pp = data.pp_max if data.pp_max < pp
        @pp = pp
        @ppmax = pp
      end
      @used = false
    end

    # Reset the skill/move information
    def reset
      @id = @id_bis
      @pp = @pp_bis if @pp_bis
      @ppmax = @pp_max_bis if @pp_max_bis
      @used = false
      @pp_bis = nil
      @pp_max_bis = nil
      @power2 = nil
      @type2 = nil
      @accuracy2 = nil
    end
  end
end
