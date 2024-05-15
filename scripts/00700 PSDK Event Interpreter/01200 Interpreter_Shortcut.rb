class Interpreter
  # Return the $game_variables
  # @return [Game_Variables]
  def gv
    $game_variables
  end

  # Return the $game_switches
  # @return [Game_Switches]
  def gs
    $game_switches
  end

  # Return the $game_temp
  # @return [Game_Temp]
  def gt
    $game_temp
  end

  # Return the $game_map
  # @return [Game_Map]
  def gm
    $game_map
  end

  # Return the $game_player
  # @return [Game_Player]
  def gp
    $game_player
  end

  # Return the $game_map.events[id]
  # @return [Game_Event]
  def ge(id = @event_id)
    gm.events[id]
  end

  # Return the party object (game state)
  # @return [PFM::GameState]
  def party
    PFM.game_state
  end

  # Return the NuriYuri::DynamicLight module
  # @return [NuriYuri::DynamicLight]
  def dynamic_light
    return NuriYuri::DynamicLight
  end
  alias dyn_light dynamic_light

  # Start the storage PC
  def start_pc
    Audio.se_play('audio/se/computeropen')
    GamePlay.open_pokemon_storage_system
  end
  alias demarrer_pc start_pc

  # Show an emotion to an event or the player
  # @param type [Symbol] the type of emotion (see wiki)
  # @param char_id [Integer] the ID of the event (> 0), the current event (0) or the player (-1)
  # @param wait [Integer] the number of frame the event will wait after this command.
  # @param params [Hash] particle
  # @note The available emotion type are :
  #   - :exclamation
  #   - :exclamation2
  #   - :poison
  #   - :interrogation
  #   - :music
  #   - :love
  #   - :joy
  #   - :sad
  #   - :happy
  #   - :angry
  #   - :sulk
  #   - :nocomment
  # @example Displaying the poison emotion :
  #   emotion(:poison)
  # @example Displaying the poison emotion on the player (with offset) :
  #   emotion(:poison, -1, 34, oy_offset: 10)
  def emotion(type, char_id = 0, wait = 34, params = {})
    Yuki::Particles.add_particle(get_character(char_id), type, params)
    @wait_count = wait
  end

  # Show an emotion on multiple events and/or the player
  # @param type [Symbol] the type of emotion (see wiki)
  # @param chars_id [Array<Integer>] the ID of the event (> 0), the current event (0) or the player (-1)
  # @param wait [Integer] the number of frame the event will wait after this command.
  # @param params [Hash] particle
  # @note See the #emotion method comments for the available emotion type
  # @example Displaying the poison emotion on the player and multiple NPCs (with offset) :
  #   emotion_on_multiple_npc(:poison, [-1, 5, 8, 15], 34, oy_offset: 10)
  def emotion_on_multiple_npc(type, chars_id = [0], wait = 34, params = {})
    chars_id.each { |char_id| emotion(type, char_id, wait, params) }
  end
  alias emotion_on_multiple_pnj emotion_on_multiple_npc

  # List of command cods that needs to be skipped in order to detect the from event calling call
  FEC_SKIP_CODES = [108, 121, 122]
  # Check if the front event calls a common event (in its first non comment commands)
  # @param common_event [Integer] the id of the common event in the database
  # @return [Boolean]
  # @author Nuri Yuri
  def front_event_calling(common_event)
    event = $game_player.front_tile_event
    if event&.list
      @event_id = event.id if @event_id == 0
      i = 0
      i += 1 while FEC_SKIP_CODES.include?(event.list[i]&.code)
      return true if event.list[i] && event.list[i].code == 117 && event.list[i].parameters[0] == common_event
    end
    return false
  end

  # Check if an event is calling a common event (in its first non comment commands)
  # @param common_event [Integer] the id of the common event
  # @param event_id [Integer] the id of the event on the MAP
  # @return [Boolean]
  def event_calling(common_event, event_id)
    if (event = $game_map.events[event_id]) && event.list
      i = 0
      i += 1 while FEC_SKIP_CODES.include?(event.list[i]&.code)
      return true if event.list[i] && event.list[i].code == 117 && event.list[i].parameters[0] == common_event
    end
    return false
  end

  # Start a choice with more option than RMXP allows.
  # @param variable_id [Integer] the id of the Variable where the choice will be store.
  # @param cancel_type [Integer] the choice that cancel (-1 = no cancel)
  # @param choices [Array<String>] the list of possible choice.
  # @author Nuri Yuri
  def choice(variable_id, cancel_type, *choices)
    setup_choices([choices, cancel_type])
    $game_temp.choice_proc = proc { |choix| $game_variables[variable_id] = choix + 1 }
  end

  # Open the world map
  # @param arg [Symbol] the mode of the world map, :view or :fly
  # @param wm_id [Integer] the world map id to display
  # @author Nuri Yuri
  def carte_du_monde(arg = :view, wm_id = $env.get_worldmap)
    arg = arg.bytesize == 3 ? :fly : :view if arg.instance_of?(String)
    if arg == :fly
      GamePlay.open_town_map_to_fly(wm_id)
    else
      GamePlay.open_town_map(wm_id)
    end
    @wait_count = 2
  end
  alias world_map carte_du_monde

  # Save the game without asking
  def force_save
    GamePlay::Save.save
  end
  alias forcer_sauvegarde force_save

  # Set the value of a self_switch
  # @param value [Boolean] the new value of the switch
  # @param self_switch [String] the name of the self switch ("A", "B", "C", "D")
  # @param event_id [Integer] the id of the event that see the self switch
  # @param map_id [Integer] the id of the map where the event see the self switch
  # @author Leikt
  def set_self_switch(value, self_switch, event_id = @event_id, map_id = @map_id)
    key = [map_id, event_id, self_switch] # Key to retrieve the local switch we want to modify
    $game_self_switches[key] = (value == true) # Modify the local switch to true or false only
    $game_map.events[event_id]&.refresh if $game_map.map_id == map_id # We refresh the event if it's on the same map, to have it account the modification
  end
  alias set_ss set_self_switch # Creating an alias: we can call the method with set_ss or with set_self_switch (as you prefer)

  # Get the value of a self_switch
  # @param self_switch [String] the name of the self switch ("A", "B", "C", "D")
  # @param event_id [Integer] the id of the event that see the self switch
  # @param map_id [Integer] the id of the map where the event see the self switch
  # @return [Boolean] the value of the self switch
  # @author Leikt
  def get_self_switch(self_switch, event_id = @event_id, map_id = @map_id)
    key = [map_id, event_id, self_switch] # Key to retrieve the local switch we want to see
    return $game_self_switches[key] || false
  end
  alias get_ss get_self_switch

  # Show the party menu in order to select a Pokemon
  # @param id_var [Integer] id of the variable in which the index will be store (-1 = no selection)
  # @param party [Array<PFM::Pokemon>] the array of Pokemon to show in the menu
  # @param mode [Symbol] the mode of the Menu (:map, :menu, :item, :hold, :battle)
  # @param extend_data [Integer, PFM::ItemDescriptor::Wrapper, Array, Symbol] extend_data informations
  # @author Nuri Yuri
  def call_party_menu(id_var = ::Yuki::Var::Party_Menu_Sel, party = $actors, mode = :map, extend_data = nil)
    block = proc { |scene| $game_variables[id_var] = scene.return_data }
    case mode
    when :map
      GamePlay.open_party_menu_to_select_pokemon(party, &block)
    when :item
      GamePlay.open_party_menu_to_use_item(extend_data, party, &block)
    when :hold
      GamePlay.open_party_menu_to_give_item_to_pokemon(extend_data, party, &block)
    when :select
      GamePlay.open_party_menu_to_select_a_party(party, PFM.game_state.game_variables[Yuki::Var::Max_Pokemon_Select], extend_data)
      $game_variables[id_var] = -1
    when :absofusion
      GamePlay.open_party_menu_to_absofusion_pokemon(party, *extend_data)
      $game_variables[id_var] = -1
    when :separate
      GamePlay.open_party_menu_to_separate_pokemon(party, extend_data)
      $game_variables[id_var] = -1
    else
      GamePlay.open_party_menu(party, &block)
    end
    @wait_count = 2
  end
  alias appel_menu_equipe call_party_menu

  # Show the quest book
  def quest_book
    GamePlay::QuestUI.new.main
    Graphics.transition
    @wait_count = 2
  end
  alias livre_quetes quest_book
  alias quest_ui quest_book
  # Add a parallax
  # @overload add_parallax(image, x, y, z, zoom_x = 1, zoom_y = 1, opacity = 255, blend_type = 0)
  #   @param image [String] name of the image in Graphics/Pictures/
  #   @param x [Integer] x coordinate of the parallax from the first pixel of the Map (16x16 tiles /!\)
  #   @param y [Integer] y coordinate of the parallax from the first pixel of the Map (16x16 tiles /!\)
  #   @param z [Integer] z superiority in the tile viewport
  #   @param zoom_x [Numeric] zoom_x of the parallax
  #   @param zoom_y [Numeric] zoom_y of the parallax
  #   @param opacity [Integer] opacity of the parallax (0~255)
  #   @param blend_type [Integer] blend_type of the parallax (0, 1, 2)
  def add_parallax(*args)
    Yuki::Particles.add_parallax(*args)
  end

  # Return the PFM::Text module
  # @return [PFM::Text]
  def pfm_text
    return PFM::Text
  end

  # Return the index of the choosen Pokemon or call a method of GameState to find the right Pokemon
  # @param method_name [Symbol] identifier of the method
  # @param args [Array] parameters to send to the method
  def pokemon_index(method_name, *args)
    index = $game_variables[Yuki::Var::Party_Menu_Sel].to_i
    index = party.send(method_name, *args) if index < 0
    return index
  end

  # Use path finding to locate the current event move else
  # @param to [Array<Integer, Integer>, Game_Character] the target, [x, y] or Game_Character object
  # @param radius [Integer] <default : 0> the distance from the target to consider it as reached
  # @param tries [Integer, Symbol] <default : 5> the number of tries allowed to this request, use :infinity to unlimited try count
  # @param type [Symbol]
  # @example find path to x=10 y=15 with an error radius of 5 tiles
  #   find_path(to:[10,15], radius:5)
  def find_path(to:, radius: 0, tries: Pathfinding::TRY_COUNT, type: nil)
    get_character(@event_id).find_path(to: to, radius: radius, tries: tries, type: type)
  end

  # Shortcut for get_character(@event_id).stop_path
  def stop_path
    get_character(@event_id).stop_path
  end

  # Shortcut defining the pathfinding request and wait for the end of the path following
  # @param x [Integer] x coords to reach
  # @param y [Integer] y coords to reach
  # @param ms [Integer] <default : 5> movement speed
  def fast_travel(x, y=nil, ms = 5)
    $game_player.move_speed = ms
    if y
      $game_player.find_path to: [x, y]
    else
      $game_player.find_path to: x, type: :Border
    end
  end

  # Shortcut for get_character(@event_id).animate_from_charset(*args)
  # @param lines [Array<Integer>] list of the lines to animates (0,1,2,3)
  # @param duration [Integer] duration of the animation in frame (60frame per secondes)
  # @param reverse [Boolean] <default: false> set it to true if the animation is reversed
  # @param repeat [Boolean] <default: false> set it to true if the animation is looped
  # @return [Boolean]
  def animate_from_charset(lines, duration, reverse: false, repeat: false, last_frame_delay: false)
    return get_character(@event_id).animate_from_charset(lines, duration, reverse: reverse, repeat: repeat, last_frame_delay: last_frame_delay)
  end

  # Wait for the end of the charset animation of this particular event
  # @param event_id [Integer] <default : calling event's> the id of the event to watch
  def wait_charset_animation(event_id = @event_id)
    @animate_charset_waiting = true
    @animate_charset_waiting_id = event_id
  end

  # Test if the Interpreter is currently waiting for an event
  # @return [Boolean]
  # @note This function automatically update the states it use if it returns false
  def waiting_animate_charset_event?
    return false unless @animate_charset_waiting
    # If we're waiting for a specific event
    if @animate_charset_waiting_id
      return true if @animate_charset_waiting_id == 0 && $game_player.charset_animation &&
                     $game_player.charset_animation[:running] && $game_player.charset_animation[:repeat] != true

      wanted_event = $game_map.events[@animate_charset_waiting_id]
      return true if wanted_event.charset_animation && wanted_event.charset_animation[:running] &&
                     wanted_event.charset_animation[:repeat] != true

      @animate_charset_waiting = false
      @animate_charset_waiting_id = nil
      return false
    end
    # Otherwise we're waiting for all event
    return true if $game_player.charset_animation[:running]
    return true if $game_map.events.any? { |_, event| event.charset_animation && event.charset_animation[:running] && event.charset_animation[:repeat] != true }

    @animate_charset_waiting = false
    return false
  end

  # Shortcut for wait_character_move_completion(0)
  # Wait for the end of the player movement
  def wait_for_player
    wait_character_move_completion 0
  end
  alias attendre_joueur wait_for_player

  # Open the casino gameplay
  # @param arg [Symbol] the mode of the casino :voltorb_flip, :slotmachine, ...
  # @param speed [Integer] speed of the slot machine
  # @author Nuri Yuri
  def casino(arg = :voltorb_flip, speed = 2)
    return if $game_variables[Yuki::Var::CoinCase] <= 0

    case arg # Anticipate the creation of other casino scenes
    when :voltorb_flip
      casino = GamePlay::Casino::VoltorbFlip.new
    when :slotmachine
      casino = GamePlay::Casino::SlotMachine.new(speed)
    else
      return
    end
    casino.main
    Graphics.transition
    @wait_count = 2
  end

  # Open the Hall of Fame UI
  # @param filename_bgm [String] the bgm to play during the Hall of Fame
  # @param context_of_victory [Symbol] the symbol to put as the context of victory
  def hall_of_fame(filename_bgm = 'audio/bgm/Hall-of-Fame', context_of_victory = :league)
    GamePlay.open_hall_of_fame(filename_bgm, context_of_victory)
    @wait_count = 2
  end

  # Open the Mining Game UI
  # @overload mining_game(item_count, music_filename = GamePlay::MiningGame::DEFAULT_MUSIC)
  #   @param item_count [Integer] the number of items to search
  #   @param music_filename [String] the filename of the music to play
  #   @param delete_after [Boolean] if the event should be deleted forever afterward
  #   @param grid_handler [PFM::MiningGame::GridHandler, nil] a specific GridHandler for this instance of the Mining Game
  # @overload mining_game(wanted_item_db_symbols, music_filename = GamePlay::MiningGame::DEFAULT_MUSIC)
  #   @param wanted_item_db_symbols [Array<Symbol>] the array containing the specific items (comprised between 1 and 5 items)
  #   @param music_filename [String] the filename of the music to play
  #   @param delete_after [Boolean] if the event should be deleted forever afterward
  #   @param grid_handler [PFM::MiningGame::GridHandler, nil] a specific GridHandler for this instance of the Mining Game
  def mining_game(param = nil, music_filename = GamePlay::MiningGame::DEFAULT_MUSIC, delete_after: true, grid_handler: nil)
    message_id = $game_map.events[@event_id].event.name.downcase.include?('miningrock') ? 2 : 0
    if PFM.game_state.bag.contain_item?(:explorer_kit)
      if yes_no_choice(ext_text(9005, message_id))
        $game_system.bgm_memorize
        $game_system.bgm_fade(0.2)
        $scene.call_scene(GamePlay::MiningGame, param, music_filename, grid_handler: grid_handler, fade_out_params: [:mining_game, 0])
        $game_system.bgm_restore
        @wait_count = 2
        delete_this_event_forever if delete_after
      end
    else
      message(ext_text(9005, message_id + 1))
      @wait_count = 2
    end
  end

  # Mirror a RMXP Picture
  # @param id [Integer] the picture id
  # @param bool [Boolean] the mirroring state
  def mirror_picture(id, bool = true)
    $game_screen.pictures[id].mirror = bool
  end

  # Give a certain amount of exp to one Pokemon
  # @param index [Integer] the Pokemon index
  # @param amount [Integer] the amount of exp to give
  def give_exp(index, amount)
    index = index.clamp(0, $actors.size - 1)
    return if $actors[index].level >= $pokemon_party.level_max_limit || $actors[index].egg?

    @amount = amount
    pokemon = $actors[index]
    exp_to_next_lvl = pokemon.exp_lvl - pokemon.exp

    while @amount >= exp_to_next_lvl
      break if pokemon.level >= $pokemon_party.level_max_limit

      pokemon.exp += exp_to_next_lvl
      @amount -= exp_to_next_lvl
      exp_to_next_lvl = pokemon.exp_lvl - pokemon.exp
      if pokemon.exp >= pokemon.exp_lvl
        pokemon.level_up_stat_refresh
        Audio.me_play(PFM::ItemDescriptor::LVL_SOUND)
        PFM::Text.set_num3(pokemon.level.to_s, 1)
        message(parse_text(18, 62, '[VAR 010C(0000)]' => pokemon.given_name))
        PFM::Text.reset_variables
        pokemon.check_skill_and_learn
        id, form = pokemon.evolve_check
        GamePlay.make_pokemon_evolve(pokemon, id, form, true) if id
      end
    end
    pokemon.exp += @amount unless pokemon.level >= $pokemon_party.level_max_limit
  end

  # Give a certain amount of exp to every Pokemon in party
  # @param amount [Integer] the amount of exp to give
  def give_exp_all(amount)
    $actors.size.times { |i| give_exp(i, amount) }
  end

  # Give a certain amount of level to one Pokemon
  # @param index [Integer] the Pokemon index
  # @param amount [Integer] the amount of level to give
  def give_level(index, amount)
    return if $actors[index].level >= $pokemon_party.level_max_limit || $actors[index].egg?

    amount.times do |i|
      break if $actors[index].level >= $pokemon_party.level_max_limit

      $actors[index].level_up_stat_refresh
      Audio.me_play(PFM::ItemDescriptor::LVL_SOUND)
      PFM::Text.set_num3($actors[index].level.to_s, 1)
      message(parse_text(18, 62, '[VAR 010C(0000)]' => $actors[index].given_name))
      PFM::Text.reset_variables
      $actors[index].check_skill_and_learn
      id, form = $actors[index].evolve_check
      GamePlay.make_pokemon_evolve($actors[index], id, form, true) if id
    end
  end

  # Give a certain amount of level to every Pokemon in party
  # @param amount [Integer] the amount of level to give
  def give_level_all(amount)
    $actors.size.times { |i| give_level(i, amount) }
  end

  # Take a screenshot of the map and save it as a png
  # @param filename [String]
  # @param scale [Integer] the scale of the final screenshot (between 1 and 3, this helps to multiply 320*240 by a factor)
  def take_screenshot(filename = 'map_screenshot%d.png', scale = 1)
    return unless $scene.is_a?(Scene_Map)

    Graphics.player_view_screenshot(filename, scale)
  end
end
