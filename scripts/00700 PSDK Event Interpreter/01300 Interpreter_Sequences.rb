class Interpreter
  include Util::SystemMessage if const_defined?(:Util)
  # Name of the file used as Received Pokemon ME (with additional parameter like volume)
  RECEIVED_POKEMON_ME = ['audio/me/rosa_yourpokemonevolved', 80]
  # Header of the system messages
  SYSTEM_MESSAGE_HEADER = ':[windowskin=m_18]:\\c[10]'
  # Default BGM used for trainer battle (sent to AudioFile so no audio/bgm)
  DEFAULT_TRAINER_BGM = ['xy_trainer_battle', 100, 100]
  # Default eye bgm for trainer encounter (direct, requires audio/bgm)
  DEFAULT_EYE_BGM = ['audio/bgm/pkmrs-enc1', 100, 100]
  # Default exclamation SE for trainer encounter (direct, requires audio/se)
  DEFAULT_EXCLAMATION_SE = ['audio/se/015-jump01', 65, 95]
  # Duration of the exclamation particle
  EXCLAMATION_PARTICLE_DURATION = 54
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

  # Start a trainer battle
  # @param trainer_id [Integer] ID of the trainer in Studio
  # @param bgm [String, Array] BGM to play for battle
  # @param disable [String] Name of the local switch to disable (if defeat)
  # @param enable [String] Name of the local switch to enable (if victory)
  # @param troop_id [Integer] ID of the troop to use : 3 = trainer, 4 = Gym Leader, 5 = Elite, 6 = Champion
  # @example Start a simple trainer battle
  #   start_trainer_battle(5) # 5 is the trainer 5 in Studio
  # @example Start a trainer battle agains a gym leader
  #   start_trainer_battle(5, bgm: '28 Pokemon Gym', troop_id: 4)
  def start_trainer_battle(trainer_id, bgm: DEFAULT_TRAINER_BGM, disable: 'A', enable: 'B', troop_id: 3)
    set_self_switch(false, disable, @event_id) # Better to disable the switch here than in defeat
    original_battle_bgm = $game_system.battle_bgm
    $game_system.battle_bgm = RPG::AudioFile.new(*bgm)
    $game_variables[Yuki::Var::Trainer_Battle_ID] = trainer_id
    $game_temp.battle_abort = true
    $game_temp.battle_calling = true
    $game_temp.battle_troop_id = troop_id
    $game_temp.battle_can_escape = false
    $game_temp.battle_can_lose = false
    $game_temp.battle_proc = proc do |n|
      yield if block_given?
      $game_variables[Yuki::Var::Trainer_Battle_ID] = 0
      $game_variables[Yuki::Var::Second_Trainer_ID] = 0
      $game_variables[Yuki::Var::Allied_Trainer_ID] = 0
      set_self_switch(true, enable, @event_id) if n == 0
      $game_system.battle_bgm = original_battle_bgm
    end    
    Yuki::FollowMe.set_battle_entry
    Yuki::FollowMe.save_follower_positions
  end

  # Start a trainer battle
  # @param trainer_id [Integer] ID of the trainer in Studio
  # @param second_trainer_id [Integer] ID of the second trainer in Studio
  # @param bgm [String, Array] BGM to play for battle
  # @param disable [String] Name of the local switch to disable (if defeat)
  # @param enable [String] Name of the local switch to enable (if victory)
  # @param troop_id [Integer] ID of the troop to use : 3 = trainer, 4 = Gym Leader, 5 = Elite, 6 = Champion
  def start_double_trainer_battle(trainer_id, second_trainer_id, bgm: DEFAULT_TRAINER_BGM, disable: 'A', enable: 'B', troop_id: 3, &block)
    start_trainer_battle(trainer_id, bgm: bgm, disable: disable, enable: enable, troop_id: troop_id, &block)
    $game_variables[Yuki::Var::Second_Trainer_ID] = second_trainer_id
  end

  # Start a trainer battle
  # @param trainer_id [Integer] ID of the trainer in Studio
  # @param second_trainer_id [Integer] ID of the second trainer in Studio
  # @param friend_trainer_id [Integer] ID of the friend trainer in Studio
  # @param bgm [String, Array] BGM to play for battle
  # @param disable [String] Name of the local switch to disable (if defeat)
  # @param enable [String] Name of the local switch to enable (if victory)
  # @param troop_id [Integer] ID of the troop to use : 3 = trainer, 4 = Gym Leader, 5 = Elite, 6 = Champion
  def start_double_trainer_battle_with_friend(trainer_id, second_trainer_id, friend_trainer_id, bgm: DEFAULT_TRAINER_BGM, disable: 'A', enable: 'B', troop_id: 3, &block)
    start_trainer_battle(trainer_id, bgm: bgm, disable: disable, enable: enable, troop_id: troop_id, &block)
    $game_variables[Yuki::Var::Second_Trainer_ID] = second_trainer_id
    $game_variables[Yuki::Var::Allied_Trainer_ID] = friend_trainer_id
  end

  # Sequence to call before start trainer battle
  # @param phrase [String] the full speech of the trainer
  # @param eye_bgm [String, Array, Integer] String => filepath, Array => filepath + volume + pitch, Integer => music from trainer resources
  # @param exclamation_se [String, Array] SE to play when the trainer detect the player
  # @example Simple eye sequence
  #   trainer_eye_sequence('Hello!')
  # @example Eye sequence with another eye_bgm
  #   trainer_eye_sequence('Hello!', eye_bgm: 'audio/bgm/pkmrs-enc7')
  def trainer_eye_sequence(phrase, eye_bgm: DEFAULT_EYE_BGM, exclamation_se: DEFAULT_EXCLAMATION_SE)
    character = get_character(@event_id)
    character.turn_toward_player
    front_coordinates = $game_player.front_tile
    # Unless the player triggered the event we show the exclamation
    unless character.x == front_coordinates.first && character.y == front_coordinates.last
      Audio.se_play(*exclamation_se)
      emotion(:exclamation)
      EXCLAMATION_PARTICLE_DURATION.times do
        move_player_and_update_graphics
      end
    end
    eye_bgm = determine_eye_sequence_bgm(eye_bgm)
    Audio.bgm_play(*eye_bgm)
    # We move to the trainer
    while (($game_player.x - character.x).abs + ($game_player.y - character.y).abs) > 1
      character.move_toward_player
      move_player_and_update_graphics while character.moving?
    end
    character.turn_toward_player
    $game_player.turn_toward_character(character)
    # We do the speech
    text = PFM::Text.parse_string_for_messages(phrase)
    message(text)
    @wait_count = 2
  end

  # Sequence that perform NPC trade
  # @param index [Integer] index of the Pokemon in the party
  # @param pokemon [PFM::Pokemon] Pokemon that is traded with
  def npc_trade_sequence(index, pokemon)
    return unless $actors[index].is_a?(PFM::Pokemon)

    actor = $actors[index]
    $actors[index] = pokemon
    $pokedex.mark_seen(pokemon.db_symbol, pokemon.form, forced: true)
    $pokedex.mark_captured(pokemon.db_symbol)
    # TODO: Trade animation taking actor, pokemon (including messages)
    message("#{actor.given_name} is being traded with #{pokemon.name}!")
    id, form = pokemon.evolve_check(:trade, actor) || pokemon.evolve_check(:tradeWith, actor)
    GamePlay.make_pokemon_evolve(pokemon, id, form, true) if id
  end

  private

  def move_player_and_update_graphics
    Graphics::FPSBalancer.global.run do
      $game_player.update
      $game_map.update
      $scene.spriteset.update
    end
    Graphics.update
  end

  # Return the filename of the BGM depending on the parameter
  # @param eye_bgm [String, Array, Integer] String for direct filepath, integer for parsing the Studio database for the right file
  # @return [Array] the array containing the filepath of the BGM, the volume and the pitch
  def determine_eye_sequence_bgm(eye_bgm)
    if eye_bgm.is_a?(Array)
      return eye_bgm if eye_bgm.first.is_a?(String)
      return DEFAULT_EYE_BGM unless (bgm_filepath = convert_trainer_id_to_bgm(eye_bgm.first))

      eye_bgm[0] = bgm_filepath
      return eye_bgm
    end

    return [eye_bgm, 100, 100] if eye_bgm.is_a?(String)
    return DEFAULT_EYE_BGM unless (bgm_filepath = convert_trainer_id_to_bgm(eye_bgm))

    return [bgm_filepath, 100, 100]
  end

  # Convert a trainer ID to something the Audio class will accept
  # @param id [Integer] the Studio trainer ID of the trainer
  # @return [String, nil] String if a music is properly setup, else nil
  def convert_trainer_id_to_bgm(id)
    return nil unless id.is_a?(Integer)
    return nil if (trainer = data_trainer(id)).id != id
    return nil if trainer&.resources&.encounter_bgm&.empty?

    return "audio/bgm/#{trainer.resources.encounter_bgm}"
  end
end
