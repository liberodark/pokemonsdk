class Interpreter
  # Name of the file used as Received Pokemon ME (with additional parameter like volume)
  RECEIVED_POKEMON_ME = ['audio/me/rosa_yourpokemonevolved', 80]
  # Header of the system messages
  SYSTEM_MESSAGE_HEADER = ':[windowskin=m_18]:\\c[10]'
  # Receive Pokemon sequence, when the player is given a Pokemon
  # @param pokemon_or_id [Integer, Symbol, PFM::Pokemon] the ID of the pokemon in the database or a Pokemon
  # @param level [Integer] the level of the Pokemon (if ID given)
  # @param shiny [Boolean, Integer] true means the Pokemon will be shiny, 0 means it'll have no chance to be shiny, other number are the chance (1 / n) the pokemon can be shiny.
  # @return [PFM::Pokemon, nil] if nil, the Pokemon couldn't be stored in the PC or added to the party. Otherwise it's the Pokemon that was added.
  def receive_pokemon_sequence(pokemon_or_id, level = 5, shiny = false)
    pokemon = add_pokemon(pokemon_or_id, level, shiny)
    if pokemon
      PFM::Text.set_pkname(pokemon)
      Audio.me_play(*RECEIVED_POKEMON_ME)
      message(SYSTEM_MESSAGE_HEADER + ext_text(8999, 15)) # Received a Pokemon
      original_name = pokemon.given_name
      while yes_no_choice(ext_text(8999, 16)) # Give a nickname ?
        rename_pokemon(pokemon)
        PFM::Text.set_pknick(pokemon)
        if pokemon.given_name == original_name || yes_no_choice(ext_text(8999, 17)) # Is that correct ?
          break
        else
          pokemon.given_name = original_name
        end
      end
      pokemon_stored_sequence(pokemon) if $game_switches[Yuki::Sw::SYS_Stored]
      PFM::Text.reset_variables
    end
    return pokemon
  end

  # Show the "Pokemon was sent to BOX $" message
  # @param pokemon [PFM::Pokemon] Pokemon sent to the box
  def pokemon_stored_sequence(pokemon)
    PFM::Text.set_pknick(pokemon)
    PFM::Text.set_variable('[VAR BOXNAME]', $storage.get_box_name($storage.current_box))
    message(SYSTEM_MESSAGE_HEADER + ext_text(8999, 18))
    PFM::Text.reset_variables
  end
end
