class Object
  private

  # Get an ability
  # @param db_symbol [Symbol] db_symbol of the ability
  # @return [Studio::Ability]
  def data_ability(db_symbol)
    return __game_data_by_id(:abilities__id, :abilities, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:abilities, db_symbol) || __game_data.dig(:abilities, :__undef__)
  end

  # Iterate through all abilities
  # @yieldparam ability [Studio::Ability]
  # @return [Enumerator<Studio::Ability>]
  def each_data_ability(&block)
    __game_data[:abilities__id].each(&block)
  end

  # Get an item
  # @param db_symbol [Symbol] db_symbol of the item
  # @return [Studio::Item]
  def data_item(db_symbol)
    return __game_data_by_id(:items__id, :items, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:items, db_symbol) || __game_data.dig(:items, :__undef__)
  end

  # Iterate through all items
  # @yieldparam item [Studio::Item]
  # @return [Enumerator<Studio::Item>]
  def each_data_item(&block)
    __game_data[:items__id].each(&block)
  end

  # Get a move
  # @param db_symbol [Symbol] db_symbol of the move
  # @return [Studio::Move]
  def data_move(db_symbol)
    return __game_data_by_id(:moves__id, :moves, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:moves, db_symbol) || __game_data.dig(:moves, :__undef__)
  end

  # Iterate through all the moves
  # @yieldparam move [Studio::Move]
  # @return [Enumerator<Studio::Move>]
  def each_data_move(&block)
    __game_data[:moves__id].each(&block)
  end

  # Get a creature
  # @param db_symbol [Symbol] db_symbol of the creature
  # @return [Studio::Creature]
  def data_creature(db_symbol)
    return __game_data_by_id(:creatures__id, :creatures, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:creatures, db_symbol) || __game_data.dig(:creatures, :__undef__)
  end
  alias data_pokemon data_creature

  # Get a creature form
  # @param db_symbol [Symbol] db_symbol of the creature
  # @param form [Integer] form of the creature
  # @return [Studio::CreatureForm]
  def data_creature_form(db_symbol, form)
    creature = data_creature(db_symbol)
    return creature.forms.find { |creature_form| creature_form.form == form } || creature.forms[0]
  end

  # Iterate through all the creatures
  # @yieldparam move [Studio::Creature]
  # @return [Enumerator<Studio::Creature>]
  def each_data_creature(&block)
    __game_data[:creatures__id].each(&block)
  end

  # Get a quest
  # @param db_symbol [Symbol] db_symbol of the quest
  # @return [Studio::Quest]
  def data_quest(db_symbol)
    return __game_data_by_id(:quests__id, :quests, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:quests, db_symbol) || __game_data.dig(:quests, :__undef__)
  end

  # Iterate through all the quests
  # @yieldparam quest [Studio::Quest]
  # @return [Enumerator<Studio::Quest>]
  def each_data_quest(&block)
    __game_data[:quests__id].each(&block)
  end

  # Get a trainer
  # @param db_symbol [Symbol] db_symbol of the trainer
  # @return [Studio::Trainer]
  def data_trainer(db_symbol)
    return __game_data_by_id(:trainers__id, :trainers, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:trainers, db_symbol) || __game_data.dig(:trainers, :__undef__)
  end

  # Iterate through all the trainers
  # @yieldparam trainer [Studio::Trainer]
  # @return [Enumerator<Studio::Trainer>]
  def each_data_trainer(&block)
    __game_data[:trainers__id].each(&block)
  end

  # Get a type
  # @param db_symbol [Symbol] db_symbol of the type
  # @return [Studio::Type]
  def data_type(db_symbol)
    return __game_data_by_id(:types__id, :types, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:types, db_symbol) || __game_data.dig(:types, :__undef__)
  end

  # Iterate through all the types
  # @yieldparam type [Studio::Type]
  # @return [Enumerator<Studio::Type>]
  def each_data_type(&block)
    __game_data[:types__id].each(&block)
  end

  # Get a zone
  # @param db_symbol [Symbol] db_symbol of the zone
  # @return [Studio::Zone]
  def data_zone(db_symbol)
    return __game_data_by_id(:zones__id, :zones, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:zones, db_symbol) || __game_data.dig(:zones, :__undef__)
  end

  # Iterate through all the zones
  # @yieldparam zone [Studio::Zone]
  # @return [Enumerator<Studio::Zone>]
  def each_data_zone(&block)
    __game_data[:zones__id].each(&block)
  end

  # Get a group
  # @param db_symbol [Symbol] db_symbol of the group
  # @return [Studio::Group]
  def data_group(db_symbol)
    return __game_data_by_id(:groups__id, :groups, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:groups, db_symbol) || __game_data.dig(:groups, :__undef__)
  end

  # Iterate through all the groups
  # @yieldparam zone [Studio::Group]
  # @return [Enumerator<Studio::Group>]
  def each_data_group(&block)
    __game_data[:groups__id].each(&block)
  end

  # Get a world map
  # @param db_symbol [Symbol] db_symbol of the world map
  # @return [Studio::WorldMap]
  def data_world_map(db_symbol)
    return __game_data_by_id(:worldmaps__id, :worldmaps, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:worldmaps, db_symbol) || __game_data.dig(:worldmaps, :__undef__)
  end

  # Iterate through all the world map
  # @yieldparam world_map [Studio::WorldMap]
  # @return [Enumerator<Studio::WorldMap>]
  def each_data_world_map(&block)
    __game_data[:worldmaps__id].each(&block)
  end

  # Get a dex
  # @param db_symbol [Symbol] db_symbol of the dex
  # @return [Studio::Dex]
  def data_dex(db_symbol)
    return __game_data_by_id(:dex__id, :dex, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:dex, db_symbol) || __game_data.dig(:dex, :__undef__)
  end

  # Iterate through all the dex
  # @yieldparam dex [Studio::Dex]
  # @return [Enumerator<Studio::Dex>]
  def each_data_dex(&block)
    __game_data[:dex__id].each(&block)
  end

  # Get a map link
  # @param db_symbol [Symbol] db_symbol of the map link
  # @return [Studio::MapLink]
  def data_map_link(db_symbol)
    return __game_data_by_id(:maplinks__id, :maplinks, db_symbol) if db_symbol.is_a?(Integer)

    return __game_data.dig(:maplinks, db_symbol) || __game_data.dig(:dex, :__undef__)
  end

  # Iterate through all the map links
  # @yieldparam map_link [Studio::MapLink]
  # @return [Enumerator<Studio::MapLink>]
  def each_data_map_link(&block)
    __game_data[:maplinks__id].each(&block)
  end

  # Get the game data
  # @return [Hash<Symbol => Hash>]
  def __game_data
    @__t = Time.new
    unless PSDK_CONFIG.release? || File.exist?('Data/Studio/psdk.dat')
      ScriptLoader.load_tool('Studio2PSDK')
      Studio2PSDK.try_convert
      Studio2PSDK.cleanup
    end
    data = load_data('Data/Studio/psdk.dat')
    log_info("Loaded PSDK data in #{(Time.new - @__t).round(4)}s")
    remove_instance_variable(:@__t)
    private Object.define_method(:__game_data) { data }
    $data_system_tags = load_data('Data/PSDK/SystemTags.rxdata')
    return __game_data
  end

  # Get the game data by id
  # @param id_storage [Symbol]
  # @param storage [Symbol]
  # @param id [Integer]
  def __game_data_by_id(id_storage, storage, id)
    return __game_data[id_storage].find { |a| a.id == id } || __game_data.dig(storage, :__undef__)
  end
end

Graphics.on_start { __game_data }
