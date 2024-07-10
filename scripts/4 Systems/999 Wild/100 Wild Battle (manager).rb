module PFM
  # The wild battle management
  #
  # The main object is stored in $wild_battle and PFM.game_state.wild_battle
  class Wild_Battle
    # List of ability that force strong Pokemon to battle (Intimidation / Regard vif)
    WEAK_POKEMON_ABILITY = %i[intimidate keen_eye]
    # List of special wild battle that are actually fishing
    FISHING_BATTLES = %i[normal super mega]
    # List of Rod
    FISHING_TOOLS = %i[old_rod good_rod super_rod]
    # List of ability giving the max level of the pokemon we can encounter
    MAX_POKEMON_LEVEL_ABILITY = %i[hustle pressure vital_spirit]
    # Mapping allowing to get the correct tool based on the input
    TOOL_MAPPING = {
      normal: :old_rod,
      super: :good_rod,
      mega: :super_rod,
      rock: :rock_smash,
      headbutt: :headbutt
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
    # Get the history of the encounters wild Pokémon
    # @return [Array<Hash>]
    attr_reader :encounters_history

    # Create a new Wild_Battle manager
    # @param game_state [PFM::GameState] variable responsive of containing the whole game state for easier access
    def initialize(game_state)
      @roaming_pokemons = []
      @forced_wild_battle = false
      @groups = []
      @game_state = game_state
      @encounters_history = []
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
      @groups_encounter_counts = []
    end

    # Load the groups of Wild Pokemon (map change/ time change)
    def load_groups
      # @type [Array<Studio::Group>]
      groups = $env.get_current_zone_data.wild_groups.map { |group_name| data_group(group_name) }
      @groups = groups.select { |group| group.custom_conditions.reduce(true) { |prev, curr| curr.reduce_evaluate(prev) } }
      @groups_encounter_steps = @groups.map { |group| group.steps_average == 0 ? $game_map.rmxp_encounter_steps : group.steps_average }
      make_encounter_count
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
      $game_temp.battle_can_lose = false
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
      if id.instance_of?(PFM::Pokemon)
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
      if @forced_wild_battle
        reset_encounters_history
        return configure_battle(@forced_wild_battle, battle_id)
      end

      # If a repel is about to finish
      if PFM.game_state.repel_on_cooldown?
        PFM.game_state.repel_step_cooldown = false
        return nil
      end

      return nil unless (group = current_selected_group)

      reset_encounters_history if can_encounters_history_reset?(group)
      maxed = MAX_POKEMON_LEVEL_ABILITY.include?(creature_ability) && rand(100) < 50
      is_double_battle = group.is_double_battle || $game_variables[Yuki::Var::Allied_Trainer_ID] > 0
      all_creatures = (group.encounters * (is_double_battle ? 2 : 1)).map do |encounter|
        encounter.to_creature(maxed ? encounter.level_setup.range.end : nil)
      end
      creature_to_select = configure_creature(all_creatures)
      selected_creature = select_creature(group, creature_to_select)
      return if selected_creature.empty?

      selected_creature.each do |creature|
        add_encounter_history(creature, group)
        reset_encounters_history if creature.shiny?
      end
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
    # @param pokemon [PFM::Pokemon]
    # @return [Boolean]
    def roaming?(pokemon)
      return roaming_pokemons.any? { |info| info.pokemon == pokemon }
    end
    alias is_roaming? roaming?

    # Add a roaming Pokemon
    # @param chance [Integer] the chance divider to see the Pokemon
    # @param proc_id [Integer] ID of the Wild_RoamingInfo::RoamingProcs
    # @param pokemon_hash [Hash, PFM::Pokemon] hash to generate the mon (cf. PFM::Pokemon#generate_from_hash), or the Pokemon
    # @return [PFM::Pokemon] the generated roaming Pokemon
    def add_roaming_pokemon(chance, proc_id, pokemon_hash)
      pokemon = pokemon_hash.is_a?(PFM::Pokemon) ? pokemon_hash : ::PFM::Pokemon.generate_from_hash(pokemon_hash)
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
      creek_amount = game_state.game_player.fishing_creek_amount
      is_inc_rate = FishIncRate.include?(creature_ability)
      return true if creek_amount >= 3

      case type
      when :mega
        rate = 60
      when :super
        rate = 45
      else
        rate = 30
      end
      rate *= 1.5 if is_inc_rate
      rate *= 1 + 0.1 * creek_amount
      result = rand(100) < rate
      reset_encounters_history unless result
      return result
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

    # Reset the history of the encounters wild Pokémon
    def reset_encounters_history
      @encounters_history = []
    end

    # Compute the fishing chain
    # @return [Integer] The total fishing chain (max 20)
    def compute_fishing_chain
      return 0 unless @encounters_history

      return @encounters_history.take_while { |encounter| %i[old_rod good_rod super_rod].include?(encounter[:tool]) }.count.clamp(0, 20)
    end

    # Method that prevent non wanted data save of the Wild_Battle object
    def begin_save
      $TMP_ENCOUNTERS_HISTORY = @encounters_history
      @encounters_history = []
    end

    # Method that end the save state of the Wild_Battle object
    def end_save
      @encounters_history = $TMP_ENCOUNTERS_HISTORY
      $TMP_ENCOUNTERS_HISTORY = nil
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

    # Add an encounter in the history
    # @param creature [PFM::Pokemon]
    # @param group [Studio::Group]
    def add_encounter_history(creature, group)
      @encounters_history ||= []
      hash = {}
      hash[:db_symbol] = creature.db_symbol
      hash[:form] = creature.form
      hash[:system_tag] = group.system_tag
      hash[:terrain_tag] = group.terrain_tag
      hash[:tool] = group.tool
      @encounters_history << hash
    end

    # Check and reset if necessary the history of the encounters
    # @param group [Studio::Group]
    def can_encounters_history_reset?(group)
      last = @encounters_history&.last
      return false unless last

      # Here we can add other rules to reset the history
      is_fishing_group = %i[old_rod good_rod super_rod].include?(group.tool)
      is_fishing_last = %i[old_rod good_rod super_rod].include?(last[:tool])
      return is_fishing_group != is_fishing_last
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
