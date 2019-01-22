#encoding: utf-8

module PFM
  class Pokemon_Party
    # Return the size of the party
    # @return [Integer]
    def size
      return @actors.size
    end
    # Is the party empty ?
    # @return [Boolean]
    def empty?
      return @actors.size == 0
    end
    # Is the party full ?
    # @return [Boolean]
    def full?
      return @actors.size == 6
    end
    # Is the party able to start a battle ?
    # @return [Boolean]
    def alive?
      @actors.each do |i|
        return true if(i and !i.dead?)
      end
      return false
    end
    # Is the party not able to start a battle ?
    def dead?
      return !self.alive?
    end
    # Number of pokemon alive in the party
    # @param max [Integer] the number of Pokemon to check from the begining of the party
    def pokemon_alive(max = @actors.size)
      alive=0
      max.times do |i|
        alive+=1 if(@actors[i] and !@actors[i].dead?)
      end
      return alive
    end
    # Add a Pokemon to the pary (also update the Pokedex Informations)
    # @param pkmn [PFM::Pokemon]
    # @return [Boolean, Integer] if the Pokemon has been added to the party or the PC. When Integer, its the id of the box where the Pokemon has been stored.
    def add_pokemon(pkmn)
      unless pkmn.egg?
        @pokedex.mark_seen(pkmn.id,pkmn.form)
        @pokedex.mark_captured(pkmn.id)
      end
      if(@actors.size>5)
        return @storage.current_box if(@storage.store(pkmn))
        return false
      else
        @actors<<pkmn
        return true
      end
    end
    # Remove a pokemon from the party
    # @param var [Integer, Symbol] the var value (index or id)
    # @param by_id [Boolean] if the pokemon are removed by their id
    # @param all [Boolean] if every pokemon that has the id are removed
    def remove_pokemon(var,by_id=false,all=false)
      var = GameData::Pokemon.get_id(var) if var.is_a?(Symbol)
      unless(by_id)
        @actors[var]=nil
      else
        @actors.each_index do |i|
          if(@actors[i].id==var)
            @actors[i]=nil
            break unless all
          end
        end
      end
      @actors.compact!
    end
    # Switch pokemon in the party
    # @param a [Integer] index of the first pokemon to switch
    # @param b [Integer] index of the second pokemon to switch
    def switch_pokemon(a,b)
      tmp=@actors[a]
      @actors[a]=@actors[b]
      @actors[b]=tmp
      @actors.compact!
    end
    # Check if the player has a specific Pokemon in its party
    # @param id [Integer, Symbol] id of the Pokemon in the database
    # @param level [Integer, nil] the level required
    # @param form [Integer, nil] the form of the Pokemon
    # @param shiny [Boolean, nil] if the Pokemon should be shiny or not
    # @param index [Boolean] if you want an index when found
    # @return [Boolean, Integer] if the Pokemon has been found
    def has_pokemon?(id, level = nil, form = nil, shiny = nil, index: false)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      @actors.each_index do |i|
        pkmn=@actors[i]
        if(pkmn.id==id)
          bool=true
          bool&&=(pkmn.level==level) if level
          bool&&=(pkmn.form==form) if form
          bool&&=(pkmn.shiny==shiny) if shiny !=nil
          return i if bool and index
          return true if bool
        end
      end
      return false
    end
    # Heal the pokemon in the Party
    def heal_party
      @actors.each do |i|
        next unless i
        i.cure
        i.hp=i.max_hp
        i.skills_set.each do |j|
          next unless j
          j.pp=j.ppmax
        end
      end
    end
    # Return the maximum level of the Pokemon in the Party
    # @return [Integer]
    def max_level
      level=0
      @actors.each do |i|
        level=i.level if i and i.level>level
      end
      return level
    end
    # Check if the party has a Pokemon with a specific skill
    # @param id [Integer, Symbol] ID of the skill in the database
    # @param index [Boolean] if the method return the index of the Pokemon that has the skill
    # @return [Boolean, Integer]
    def has_skill?(id, index = false)
      id = GameData::Skill.get_id(id) if id.is_a?(Symbol)
      @actors.each_with_index do |pokemon, i|
        next unless pokemon
        pokemon.skills_set.each do |skill|
          next unless skill
          if skill.id == id
            return index ? i : true
          end
        end
      end
      return false
    end
    # Check if the party has a Pokemon with a specific ability
    # @param id [Integer, Symbol] ID of the ability in the database
    # @param index [Boolean] if the method return the index of the Pokemon that has the ability
    # @return [Boolean, Integer]
    def has_ability?(id, index = false)
      id = GameData::Abilities.find_using_symbol(id) if id.is_a?(Symbol)
      @actors.each_with_index do |pokemon, i|
        next unless pokemon
        if pokemon.ability == id
          return index ? i : true
        end
      end
      return false
    end
    # Checks if one Pokemon of the party can learn the requested skill.
    # @overload can_learn?(id)
    #   @param id [Integer, Symbol] the id of the skill in the database
    #   @return [Boolean]
    # @overload can_learn?(id, index)
    #   Returns the position of the first pokemon that meets conditions
    #   @param id [Integer, Symbol] the id of the skill in the database
    #   @param index [true] indicating to return the index
    #   @return [Integer, false]
    def can_learn?(id, index = false)
      id = GameData::Skill.get_id(id) if id.is_a?(Symbol)
      @actors.each_with_index do |pokemon, i|
        next unless pokemon
        if pokemon.can_learn?(id)
          return index ? i : true
        end
      end
      return false
    end
    # Checks if one Pokemon of the party can learn or has learnt the requested skill.
    # @overload can_learn_or_learnt?(id)
    #   @param id [Integer, Symbol] the id of the skill in the database
    #   @return [Boolean]
    # @overload can_learn_or_learnt?(id, index)
    #   Returns the position of the first pokemon that meets conditions
    #   @param id [Integer, Symbol] the id of the skill in the database
    #   @param index [true] indicating to return the index
    #   @return [Integer, false]
    def can_learn_or_learnt?(id, index = false)
      id = GameData::Skill.get_id(id) if id.is_a?(Symbol)
      @actors.each_with_index do |pokemon, i|
        next unless pokemon
        if pokemon.can_learn?(id) != false
          return index ? i : true
        end
      end
      return false
    end
  end
end
