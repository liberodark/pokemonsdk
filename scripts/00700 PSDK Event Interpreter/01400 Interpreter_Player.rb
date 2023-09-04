class Interpreter
  # Save the bag somewhere and make it empty in the point of view of the player.
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_bag
  # @author Beef'
  def empty_and_save_bag(id_storage = nil)
    var_id = id_storage ? "@_str_bag_#{id_storage}".to_sym : :@other_bag
    bag = Marshal.load(Marshal.dump($bag))
    $bag = PFM::Bag.new
    $storage.instance_variable_set(var_id, bag)
  end
  
  # Retrieve the saved bag when emptied ( /!\ empty the current bag)
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_bag
  # @author Beef'
  def retrieve_saved_bag(id_storage = nil)
    var_id = id_storage ? "@_str_bag_#{id_storage}".to_sym : :@other_bag
    bag = $storage.instance_variable_get(var_id)
    return nil if bag.empty?
    $bag = PFM.game_state.bag = bag
    $storage.remove_instance_variable(var_id) if id_storage
  end

  # Save the trainer somewhere and make it empty in the point of view of the player.
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_trainer
  # @author Beef'
  def empty_and_save_trainer(id_storage = nil)
    var_id = id_storage ? "@_str_trainer_#{id_storage}".to_sym : :@other_trainer
    trainer = Marshal.load(Marshal.dump($trainer))
    $trainer = PFM::Trainer.new
    $storage.instance_variable_set(var_id, trainer)
  end
  
  # Retrieve the saved trainer 
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_trainer
  # @author Beef'
  def retrieve_saved_trainer(id_storage = nil)
    var_id = id_storage ? "@_str_trainer_#{id_storage}".to_sym : :@other_trainer
    trainer = $storage.instance_variable_get(var_id)
    return nil if !trainer.is_a? PFM::Trainer
    $trainer = PFM.game_state.trainer = trainer
    PFM.game_state.game_switches[Yuki::Sw::Gender] = $trainer.playing_girl
    $storage.remove_instance_variable(var_id) if id_storage
  end 

  # Save the pokedex somewhere and make it empty in the point of view of the player.
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_pokedex
  # @author Beef'
  def empty_and_save_pokedex(id_storage = nil)
    var_id = id_storage ? "@_str_pokedex_#{id_storage}".to_sym : :@other_pokedex
    pokedex = Marshal.load(Marshal.dump($pokedex))
    $pokedex = PFM::Pokedex.new
    $storage.instance_variable_set(var_id, pokedex)
  end
  
  # Retrieve the saved pokedex when emptied
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_pokedex
  # @author Beef'
  def retrieve_saved_pokedex(id_storage = nil)
    var_id = id_storage ? "@_str_pokedex_#{id_storage}".to_sym : :@other_pokedex
    pokedex = $storage.instance_variable_get(var_id)
    return nil if !pokedex.is_a? PFM::Pokedex
    $pokedex = PFM.game_state.pokedex = pokedex
    $storage.remove_instance_variable(var_id) if id_storage
  end

  # Save the money somewhere and make it null in the point of view of the player.
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_money
  # @author Beef'
  def empty_and_save_money(id_storage = nil)
    var_id = id_storage ? "@_str_money_#{id_storage}".to_sym : :@other_money
    money = Marshal.load(Marshal.dump(PFM.game_state.money))
    PFM.game_state.money = 0
    $storage.instance_variable_set(var_id, money)
  end
  
  # Retrieve the saved money 
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_money
  # @author Beef'
  def retrieve_saved_money(id_storage = nil)
    var_id = id_storage ? "@_str_money_#{id_storage}".to_sym : :@other_money
    money = $storage.instance_variable_get(var_id)
    return nil if !money.is_a? Integer
    PFM.game_state.money = money
    $storage.remove_instance_variable(var_id) if id_storage
  end 

  # Save the appearance somewhere and set the default in the point of view of the player.
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_appearance
  # @author Beef'
  def empty_and_save_appearance(id_storage = nil) 
    var_id = id_storage ? "@_str_appearance_#{id_storage}".to_sym : :@other_appearance
    charset_base = Marshal.load(Marshal.dump($game_player.charset_base))
    $game_player.set_appearance_set(nil.to_s)
    $storage.instance_variable_set(var_id, charset_base)
  end
  
  # Retrieve the saved appearance 
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_appearance
  # @author Beef'
  def retrieve_saved_appearance(id_storage = nil)
    var_id = id_storage ? "@_str_appearance_#{id_storage}".to_sym : :@other_appearance
    charset_base = $storage.instance_variable_get(var_id)
    return nil if !charset_base.is_a? String
    $game_player.set_appearance_set(charset_base)
    $storage.remove_instance_variable(var_id) if id_storage
  end

  # Save the team somewhere and make it empty in the point of view of the player.
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_party
  # @author Nuri Yuri
  def empty_and_save_party(id_storage = nil)
    var_id = id_storage ? "@_str_#{id_storage}".to_sym : :@other_party
    $actors.compact!
    party = Marshal.load(Marshal.dump($actors))
    $actors.clear
    $storage.instance_variable_set(var_id, party)
  end

  # Retrieve the saved team when emptied ( /!\ empty the current team)
  # @param id_storage [String] the specific name of the storage, if nil sent to $storage.other_party
  # @author Nuri Yuri
  def retrieve_saved_party(id_storage = nil)
    var_id = id_storage ? "@_str_#{id_storage}".to_sym : :@other_party
    party = $storage.instance_variable_get(var_id)
    return nil if party.empty?
    $actors.each do |pokemon|
      $storage.store(pokemon)
    end
    $actors = PFM.game_state.actors = party
    $storage.remove_instance_variable(var_id) if id_storage
  end
  alias retreive_saved_party retrieve_saved_party

  # Switch from one player to another, in term of party, trainer, money, pokedex and appearance (all optional)
  # @param from_player_id [String] the specific name of the storage to save to.
  # @param to_player_id [String] the specific name of the storage to load from.
  # @author Beef'
  def switch_player(
    from_player_id, 
    to_player_id,
    switch_bag: true, 
    switch_party: true, 
    switch_trainer: true, 
    switch_appearance: true,
    switch_money: true, 
    switch_pokedex: true 
    )
    if switch_bag
      empty_and_save_bag(from_player_id)
      retrieve_saved_bag(to_player_id)
    end      
    if switch_party
      empty_and_save_party(from_player_id)
      retrieve_saved_party(to_player_id)
    end
    if switch_trainer
      empty_and_save_trainer(from_player_id)
      retrieve_saved_trainer(to_player_id) 
    end
    if switch_appearance
      empty_and_save_appearance(from_player_id)
      retrieve_saved_appearance(to_player_id) 
    end
    if switch_money
      empty_and_save_money(from_player_id)
      retrieve_saved_money(to_player_id) 
    end
    if switch_pokedex
      empty_and_save_pokedex(from_player_id)
      retrieve_saved_pokedex(to_player_id) 
    end
  end

  # Switch from one player to another, in term of party, trainer, money, pokedex and appearance (all optional)
  # The Yuki::Var::Current_Player_ID must be defined beforehand
  # @param to_player_id [String] the specific name of the storage to load from.
  # @author Beef'
  def switch_player_safe(
    to_player_id,
    switch_bag: true, 
    switch_party: true, 
    switch_trainer: true, 
    switch_appearance: true,
    switch_money: true, 
    switch_pokedex: true 
    )
    from_player_id = $game_variables[Yuki::Var::Current_Player_ID]
    return nil if to_player_id == from_player_id
    switch_player(
      from_player_id, 
      to_player_id,
      switch_bag: switch_bag, 
      switch_party: switch_party, 
      switch_trainer: switch_trainer, 
      switch_appearance: switch_appearance,
      switch_money: switch_money, 
      switch_pokedex: switch_pokedex 
      )
    $game_variables[Yuki::Var::Current_Player_ID] = to_player_id
  end
end