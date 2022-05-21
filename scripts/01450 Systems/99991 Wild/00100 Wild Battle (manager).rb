module PFM
  # The wild battle management
  #
  # The main object is stored in $wild_battle and PFM.game_state.wild_battle
  class Wild_Battle
    # List of ability that force strong Pokemon to battle (Intimidation / Regard vif)
    WEAK_POKEMON_ABILITY = %i[intimidate keen_eye]
    # List of special wild battle that are actually fishing
    FISHING_BATTLES = %i[normal super mega]
    # List of ability giving the max level of the pokemon we can encounter
    MAX_POKEMON_LEVEL_ABILITY = %i[hustle pressure vital_spirit]
    # Mapping allowing to get the correct tool based on the input
    TOOL_MAPPING = {
      normal: :OldRod,
      super: :GoodRod,
      mega: :SuperRod,
      rock: :RockSmash,
      headbutt: :HeadButt
    }
    # List of Roaming Pokemon
    # @return [Array<PFM::Wild_RoamingInfo>]
    attr_reader :roaming_pokemons
    # List of Remaining creature groups
    # @return [Array<Studio::Group>]
    attr_reader :groups
    # Get the game state responsive of the whole game state
    # @return [PFM::GameState]
    attr_accessor :game_state

    # Create a new Wild_Battle manager
    # @param game_state [PFM::GameState] variable responsive of containing the whole game state for easier access
    def initialize(game_state)
      @roaming_pokemons = []
      @forced_wild_battle = false
      @groups = []
      @game_state = game_state
    end

    # Reset the wild battle
    def reset
      @groups&.clear
      @roaming_pokemons.each(&:update)
      @roaming_pokemons.delete_if(&:pokemon_dead?)
      PFM::Wild_RoamingInfo.lock
      # @forced_wild_battle=false
      @fished = false
      @fish_battle = nil
    end

    # Load the groups of Wild Pokemon (map change/ time change)
    def load_groups
      # @type [Array<Studio::Group>]
      groups = $env.get_current_zone_data.wild_groups.map { |group_name| data_group(group_name) }
      @groups = groups.select { |group| group.custom_conditions.reduce(true) { |prev, curr| curr.reduce_evaluate(prev) } }
    end

    # Is a wild battle available ?
    # @return [Boolean]
    def available?
      return false if $scene.is_a?(Battle::Scene)
      return false if game_state.pokemon_alive == 0
      return true if @fish_battle
      return true if roaming_battle_available?

      @forced_wild_battle = false
      return remaining_battle_available?
    end

    # Test if there's any fish battle available and start it if asked.
    # @param rod [Symbol] the kind of rod used to fish : :norma, :super, :mega
    # @param start [Boolean] if the battle should be started
    # @return [Boolean, nil] if there's a battle available
    def any_fish?(rod = :normal, start = false)
      return false unless game_state.env.can_fish?

      system_tag = game_state.game_player.front_system_tag_db_symbol
      terrain_tag = game_state.game_player.front_terrain_tag
      tool = TOOL_MAPPING[rod] || :__undef__
      current_group = @groups.find { |group| group.tool == tool && group.system_tag == system_tag && group.terrain_tag == terrain_tag }
      return false unless current_group

      if start
        @fish_battle = current_group
        if FISHING_BATTLES.include?(rod)
          @fished = true
        else
          @fished = false
        end
        return nil
      else
        return true
      end
    end

    # Test if there's any hidden battle available and start it if asked.
    # @param rod [Symbol] the kind of rod used to fish : :rock, :headbutt
    # @param start [Boolean] if the battle should be started
    # @return [Boolean, nil] if there's a battle available
    def any_hidden_pokemon?(rod = :rock, start = false)
      system_tag = game_state.game_player.front_system_tag_db_symbol
      terrain_tag = game_state.game_player.front_terrain_tag
      tool = TOOL_MAPPING[rod] || :__undef__
      current_group = @groups.find { |group| group.tool == tool && group.system_tag == system_tag && group.terrain_tag == terrain_tag }
      return false unless current_group

      if start
        @fish_battle = current_group
        @fished = false
        return nil
      else
        return true
      end
    end

    # Start a wild battle
    # @overload start_battle(id, level, *args)
    #   @param id [PFM::Pokemon] First Pokemon in the wild battle.
    #   @param level [Object] ignored
    #   @param args [Array<PFM::Pokemon>] other pokemon in the wild battle.
    #   @param battle_id [Integer] ID of the events to load for battle scenario
    # @overload start_battle(id, level, *args)
    #   @param id [Integer] id of the Pokemon in the database
    #   @param level [Integer] level of the first Pokemon
    #   @param args [Array<Integer, Integer>] array of id, level of the other Pokemon in the wild battle.
    #   @param battle_id [Integer] ID of the events to load for battle scenario
    def start_battle(id, level = 70, *others, battle_id: 1)
      init_battle(id, level, *others)
      Graphics.freeze
      $scene = Battle::Scene.new(setup(battle_id))
      Yuki::FollowMe.set_battle_entry
    end

    # Init a wild battle
    # @note Does not start the battle
    # @overload init_battle(id, level, *args)
    #   @param id [PFM::Pokemon] First Pokemon in the wild battle.
    #   @param level [Object] ignored
    #   @param args [Array<PFM::Pokemon>] other pokemon in the wild battle.
    # @overload init_battle(id, level, *args)
    #   @param id [Integer] id of the Pokemon in the database
    #   @param level [Integer] level of the first Pokemon
    #   @param args [Array<Integer, Integer>] array of id, level of the other Pokemon in the wild battle.
    def init_battle(id, level = 70, *others)
      if id.class == PFM::Pokemon
        @forced_wild_battle = [id, *others]
      else
        id = data_creature(id).id if id.is_a?(Symbol)
        @forced_wild_battle = [PFM::Pokemon.new(id, level)]
        0.step(others.size - 1, 2) do |i|
          others[i] = data_creature(others[i]).id if others[i].is_a?(Symbol)
          @forced_wild_battle << PFM::Pokemon.new(others[i], others[i + 1])
        end
      end
    end

    # Set the Battle::Info with the right information
    # @param battle_id [Integer] ID of the events to load for battle scenario
    # @return [Battle::Logic::BattleInfo, nil]
    def setup(battle_id = 1)
      # If it was a forced battle
      return configure_battle(@forced_wild_battle, battle_id) if @forced_wild_battle
      # Security for when a Repel is used at the same time an encounter is happening
      return nil if PFM.game_state.repel_count > 0
      return nil unless (group = current_selected_group)

      maxed = MAX_POKEMON_LEVEL_ABILITY.include?(creature_ability) && rand(100) < 50
      all_creatures = (group.encounters * (group.is_double_battle ? 2 : 1)).map do |encounter|
        encounter.to_creature(maxed ? encounter.level_setup.range.end : nil)
      end
      creature_to_select = configure_creature(all_creatures)
      selected_creature = select_creature(group, creature_to_select)
      return configure_battle(selected_creature, battle_id)
    ensure
      @forced_wild_battle = false
      @fish_battle = nil
    end

    # Define a group of remaining wild battle
    # @param zone_type [Integer] type of the zone, see $env.get_zone_type to know the id
    # @param tag [Integer] terrain_tag on which the player should be to start a battle with wild Pokemon of this group
    # @param delta_level [Integer] the disparity of the Pokemon levels
    # @param vs_type [Integer] the vs_type the Wild Battle are
    # @param data [Array<Integer, Integer, Integer>, Array<Integer, Hash, Integer>] Array of id, level/informations, chance to see (Pokemon informations)
    def set(zone_type, tag, delta_level, vs_type, *data)
      raise 'This method is no longer supported'
    end

    # Test if a Pokemon is a roaming Pokemon (Usefull in battle)
    # @return [Boolean]
    def roaming?(pokemon)
      return roaming_pokemons.any? { |info| info.pokemon == pokemon }
    end
    alias is_roaming? roaming?

    # Add a roaming Pokemon
    # @param chance [Integer] the chance divider to see the Pokemon
    # @param proc_id [Integer] ID of the Wild_RoamingInfo::RoamingProcs
    # @param pokemon_hash [Hash] the Hash that help the generation of the Pokemon, see PFM::Pokemon#generate_from_hash
    # @return [PFM::Pokemon] the generated roaming Pokemon
    def add_roaming_pokemon(chance, proc_id, pokemon_hash)
      pokemon = ::PFM::Pokemon.generate_from_hash(pokemon_hash)
      PFM::Wild_RoamingInfo.unlock
      @roaming_pokemons << Wild_RoamingInfo.new(pokemon, chance, proc_id)
      PFM::Wild_RoamingInfo.lock
      return pokemon
    end

    # Remove a roaming Pokemon from the roaming Pokemon array
    # @param pokemon [PFM::Pokemon] the Pokemon that should be removed
    def remove_roaming_pokemon(pokemon)
      roaming_pokemons.delete_if { |i| i.pokemon == pokemon }
    end

    # Ability that increase the rate of any fishing rod # Glue / Ventouse
    FishIncRate = %i[sticky_hold suction_cups]

    # Check if a Pokemon can be fished there with a specific fishing rod type
    # @param type [Symbol] :mega, :super, :normal
    # @return [Boolean]
    def check_fishing_chances(type)
      case type
      when :mega
        rate = 60
      when :super
        rate = 45
      else
        rate = 30
      end
      rate *= 1.5 if FishIncRate.include?(creature_ability)
      return rate < rand(100)
    end

    # yield a block on every available roaming Pokemon
    def each_roaming_pokemon
      @roaming_pokemons.each do |roaming_info|
        yield(roaming_info.pokemon)
      end
    end

    # Tell the roaming pokemon that the playe has look at their position
    def on_map_viewed
      @roaming_pokemons.each do |info|
        info.spotted = true
      end
    end

    private

    # Test if a roaming battle is available
    # @return [Boolean]
    def roaming_battle_available?
      # @type [PFM::Wild_RoamingInfo]
      return false unless (info = roaming_pokemons.find(&:appearing?))

      PFM::Wild_RoamingInfo.unlock
      info.spotted = true
      init_battle(info.pokemon)
      return true
    end

    # Test if a remaining battle is available
    # @return [Boolean]
    def remaining_battle_available?
      system_tag = game_state.game_player.system_tag_db_symbol
      terrain_tag = game_state.game_player.terrain_tag
      current_group = @groups.find { |group| group.tool.nil? && group.system_tag == system_tag && group.terrain_tag == terrain_tag }
      return false unless current_group

      actor_level = $actors[0].level
      if PFM.game_state.repel_count > 0 && current_group.encounters.all? { |encounter| encounter.level_setup.repel_rejected(actor_level) }
        return false
      end

      if WEAK_POKEMON_ABILITY.include?(creature_ability)
        return current_group.encounters.any? { |encounter| encounter.level_setup.strong_selected(actor_level) } || rand(100) < 50
      end

      return true
    end

    # Function that returns the Creature ability of the Creature triggering all the stuff related to ability
    # @return [Symbol] db_symbol of the ability
    def creature_ability
      return :__undef__ unless game_state.actors[0]

      return game_state.actors[0].ability_db_symbol
    end

    # Get the current selected group
    # @return [Studio::Group, nil]
    def current_selected_group
      return @fish_battle if @fish_battle

      system_tag = game_state.game_player.system_tag_db_symbol
      terrain_tag = game_state.game_player.terrain_tag
      return @groups.find { |group| group.tool.nil? && group.system_tag == system_tag && group.terrain_tag == terrain_tag }
    end
  end

  # Retro compatibility with saves
  Wild_Info = Object

  class GameState
    # The information about the Wild Battle
    # @return [PFM::Wild_Battle]
    attr_accessor :wild_battle

    on_player_initialize(:wild_battle) { @wild_battle = PFM::Wild_Battle.new(self) }
    on_expand_global_variables(:wild_battle) do
      $wild_battle = @wild_battle
      @wild_battle.game_state = self
    end
  end
end
