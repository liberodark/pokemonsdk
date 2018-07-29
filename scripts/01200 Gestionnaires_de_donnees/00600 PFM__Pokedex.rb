#encoding: utf-8

module PFM
  # The Pokedex informations
  # 
  # The main Pokedex object is stored in $pokedex or $pokemon_party.pokedex
  # @author Nuri Yuri
  class Pokedex
    # Create a new Pokedex object
    def initialize
      @seen=0
      @captured=0
      @has_seen_and_forms=Array.new($game_data_pokemon.size,0)
      @has_captured=Array.new($game_data_pokemon.size,false)
      @nb_fought=Array.new($game_data_pokemon.size,0)
      @nb_captured=Array.new($game_data_pokemon.size,0)
    end
    # Enable the Pokedex
    def enable
      $game_switches[Yuki::Sw::Pokedex] = true
    end
    # Disable the Pokedex
    def disable
      $game_switches[Yuki::Sw::Pokedex] = false
    end
    # Set the national flag of the Pokedex
    # @param mode [Boolean] the flag
    def set_national(mode)
      $game_switches[Yuki::Sw::Pokedex_Nat] = (mode == true)
    end
    # Is the Pokedex showing national Pokemon
    # @return [Boolean]
    def national?
      return $game_switches[Yuki::Sw::Pokedex_Nat]
    end
    # Return the number of Pokemon seen
    # @return [Integer]
    def pokemon_seen
      return @seen
    end
    # Return the number of captured Pokemon
    # @return [Integer]
    def pokemon_captured
      return @captured
    end
    # Return the number of Pokemon captured by specie
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @return [Integer]
    def pokemon_captured_count(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      return @nb_captured[id]
    end
    # Change the number of Pokemon captured by specie
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @param nb [Integer] the new number
    def pokemon_captured_set_count(id, nb)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      @nb_captured[id] = nb
    end
    # Increase the number of pokemon captured by specie
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    def pokemon_captured_add(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      @nb_captured[id] += 1
    end
    # Return the number of Pokemon fought by specie
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @return [Integer]
    def pokemon_fought(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      return @nb_fought[id]
    end
    # Change the number of Pokemon fought by specie
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    def pokemon_mark_fought(id, nb)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      @nb_fought[id] = nb
    end
    # Increase the number of Pokemon fought by specie
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    def pokemon_fought_add(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      @nb_fought[id] += 1
    end
    # Mark a pokemon as seen
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @param form [Integer] the specific form of the Pokemon
    def mark_seen(id, form=0)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      @seen+=1 if @has_seen_and_forms[id]==0
      @has_seen_and_forms[id]|=(1<<form)
      $game_variables[Yuki::Var::Pokedex_Seen]=@seen
    end
    # Unmark a pokemon as seen
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @param form [Integer, false] if false, all form will be unseen, otherwise the specific form will be unseen
    def unmark_seen(id,form=false)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      if(form)
        @has_seen_and_forms[id] &= (~(1<<form))
      else
        @has_seen_and_forms[id] = 0
      end
      @seen -=1 if @has_seen_and_forms[id] == 0
      $game_variables[Yuki::Var::Pokedex_Seen] = @seen
    end
    # Mark a Pokemon as captured
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    def mark_captured(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      unless @has_captured[id]
        @has_captured[id] = true
        @captured += 1
      end
      $game_variables[Yuki::Var::Pokedex_Catch] = @captured
    end
    # Unmark a Pokemon as captured
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    def unmark_captured(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      if @has_captured[id]
        @has_captured[id]=false
        @captured-=1
      end
      $game_variables[Yuki::Var::Pokedex_Catch]=@captured
    end
    # Has the player seen a Pokemon
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @return [Boolean]
    def has_seen?(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      return @has_seen_and_forms[id] != 0
    end
    # Has the player captured a Pokemon
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @return [Boolean]
    def has_captured?(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      return @has_captured[id]
    end
    # Get the seen forms informations of a Pokemon
    # @param id [Integer, Symbol] the id of the Pokemon in the database
    # @return [Integer]
    def get_forms(id)
      id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
      return @has_seen_and_forms[id]
    end
    # Calibrate the Pokedex information (seen/captured)
    def calibrate
      @seen = 0
      @captured = 0
      1.step($game_data_pokemon.size-1) do |id|
        @seen += 1 if @has_seen_and_forms[id] != 0
        @captured += 1 if @has_captured[id]
      end
      $game_variables[Yuki::Var::Pokedex_Catch] = @captured
      $game_variables[Yuki::Var::Pokedex_Seen] = @seen
    end
  end
end
