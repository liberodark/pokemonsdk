#encoding: utf-8

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

  # Return the $pokemon_party
  # @return [PFM::Pokemon_Party]
  def party
    $pokemon_party
  end

  # Start the storage PC
  def start_pc
    pc = ::GamePlay::Storage.new
    pc.main
  end
  alias demarrer_pc start_pc

  # Show an emotion to an event or the player
  # @param type [Symbol] the type of emotion (see wiki)
  # @param char_id [Integer] the ID of the event (> 0), the current event (0) or the player (-1)
  # @param wait [Integer] the number of frame the event will wait after this command.
  def emotion(type, char_id = 0, wait = 34)
    Yuki::Particles.add_particle(get_character(char_id), type)
    @wait_count = wait
  end

  # Check if the front event calls a common event (in its first non comment commands)
  # @param common_event [Integer] the id of the common event in the database
  # @return [Boolean]
  # @author Nuri Yuri
  def front_event_calling(common_event)
    v = $game_player.front_tile_event
    if(v)
      i = 0
      while(v.list[i] and v.list[i].code.between?(121, 122))
        i +=1
      end
      return true if(v.list[i] and v.list[i].code == 117 and v.list[i].parameters[0] == common_event)
    end
    return false
  end

  # Check if an event is calling a common event (in its first non comment commands)
  # @param common_event [Integer] the id of the common event
  # @param event_id [Integer] the id of the event on the MAP
  # @return [Boolean]
  def event_calling(common_event, event_id)
    if (v = $game_map.events[event_id]) && v.list
      i = 0
      i += 1 while v.list[i] && v.list[i].code.between?(121, 122)
      return true if v.list[i] && v.list[i].code == 117 && v.list[i].parameters[0] == common_event
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
    $game_temp.choice_proc = proc { |choix| $game_variables[ variable_id ] = choix + 1}
  end

  # Open the world map
  # @param arg [Symbol] the mode of the world map, :view or :fly
  # @author Nuri Yuri
  def carte_du_monde(arg = :view)
    if arg.class == String
      arg = arg.bytesize == 3 ? :fly : :view
    end
    carte = GamePlay::WorldMap.new(arg)
    carte.main
    Graphics.transition
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
  def set_self_switch(value, self_switch, event_id, map_id = @map_id) # Notre fonction
    key = [map_id, event_id, self_switch]  # Clef pour retrouver l'interrupteur local que l'on veut modifier
    $game_self_switches[key] = (value == true) # Modification de l'interrupteur local (on le veut à True ou à False)
    $game_map.events[event_id].refresh if $game_map.map_id == map_id # On rafraichi l'event s'il est sur la même map, pour qu'il prenne en compte la modification
  end
  alias set_ss set_self_switch # Création d'un alias : on peut appeler notre fonction par set_ss ou par set_self_switch (comme vous préférer)

  # Get the value of a self_switch
  # @param self_switch [String] the name of the self switch ("A", "B", "C", "D")
  # @param event_id [Integer] the id of the event that see the self switch
  # @param map_id [Integer] the id of the map where the event see the self switch
  # @return [Boolean] the value of the self switch
  # @author Leikt
  def get_self_switch(self_switch, event_id, map_id = @map_id)
    key = [map_id, event_id, self_switch]  # Clef pour retrouver l'interrupteur local que l'on veut modifier
    return $game_self_switches[key]
  end
  alias get_ss get_self_switch
  # Show the party menu in order to select a Pokemon
  # @param id_var [Integer] id of the variable in which the index will be store (-1 = no selection)
  # @param party [Array<PFM::Pokemon>] the array of Pokemon to show in the menu
  # @param mode [Symbol] the mode of the Menu (:map, :menu, :item, :hold, :battle)
  # @author Nuri Yuri
  def call_party_menu(id_var = ::Yuki::Var::TMP1, party = $actors, mode = :map)
    Graphics.freeze
    scene = GamePlay::Party_Menu.new(party, mode)
    scene.main
    $game_variables[id_var] = scene.return_data
    Graphics.transition
    @wait_count = 2
  end
  alias appel_menu_equipe call_party_menu
  # Show the quest book
  def quest_book
    GamePlay::QuestBookMenu.new.main
    Graphics.transition
    @wait_count = 2
  end
  alias livre_quetes quest_book
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

  # Add an item to the bag if possible, will delete the event forever
  # @param item_id [Integer] id of the item in the database
  # @param no_delete [Boolean] bypass the deletion of the event
  def add_item(item_id, no_delete = false)
    item_id = GameData::Item.get_id(item_id) if item_id.is_a?(Symbol)
    @message_waiting = true
    (text = ::PFM::Text).reset_variables
    if (max = GameData::Bag::MaxItem) > 0
      if $bag.item_quantity(item_id) >= max
        str = _parse(41, 7, text::ITEM2[1] => ::GameData::Item.name(item_id),
          text::TRNAME[0] => $trainer.name)
        $scene.display_message(str)
        return @wait_count = 2
      end
    end
    misc_data = ::GameData::Item.misc_data(item_id)
    if misc_data and misc_data.skill_learn
      str = _parse(41, 6, text::ITEM2[1] => ::GameData::Item.name(item_id),
        text::TRNAME[0] => $trainer.name,
        text::MOVE[2] => ::GameData::Skill.name(misc_data.skill_learn))
    else
      str = _parse(41, 4, text::ITEM2[1] => ::GameData::Item.name(item_id),
        text::TRNAME[0] => $trainer.name)
    end
    socket = GameData::Item.socket(item_id)
    Audio.me_play(ItemGetME[(socket == 3 ? 2 : (socket == 5 ? 1 : 0))], 80)
    $scene.display_message(str)
    str = _parse(41, 9, text::ITEM2[1] => ::GameData::Item.name(item_id),
        text::TRNAME[0] => $trainer.name,
        "[VAR 0112(0002)]" => GameData::Bag.get_socket_name(socket))
    @message_waiting = true
    $scene.display_message(str)
    $bag.add_item(item_id, 1)
    @message_waiting = false
    delete_this_event_forever unless no_delete
    @wait_count = 2
  end

  # Return the PFM::Text module
  # @return [PFM::Text]
  def pfm_text
    return PFM::Text
  end

  # Return the index of the choosen Pokemon or call a method of Pokemon_Party to find the right Pokemon
  # @param method_name [Symbol] identifier of the method
  # @param args [Array] parameters to send to the method
  def pokemon_index(method_name, *args)
    index = $game_variables[Yuki::Var::Party_Menu_Sel].to_i
    index = party.send(method_name, *args) if index < 0
    return index
  end
end
