class Interpreter
  include Util::SystemMessage if const_defined?(:Util)
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
      Audio.me_play(*RECEIVED_POKEMON_ME)
      show_message(:received_pokemon, pokemon: pokemon, header: SYSTEM_MESSAGE_HEADER)
      original_name = pokemon.given_name
      while yes_no_choice(load_message(:give_nickname_question))
        rename_pokemon(pokemon)
        if pokemon.given_name == original_name ||
           yes_no_choice(load_message(:is_nickname_correct_qesion, pokemon: pokemon))
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
    show_message(:pokemon_stored_to_box,
                 pokemon: pokemon,
                 '[VAR BOXNAME]' => $storage.get_box_name($storage.current_box),
                 header: SYSTEM_MESSAGE_HEADER)
  end
end
