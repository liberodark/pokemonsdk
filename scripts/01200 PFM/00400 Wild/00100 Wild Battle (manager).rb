module PFM
  # The wild battle management
  #
  # The main object is stored in $wild_battle and $pokemon_party.wild_battle
  # @author Nuri Yuri
  class Wild_Battle
    # The number of zone type that can be stored
    MAX_ZONE_COUNT = 10
    # List of ability that force strong Pokemon to battle (Intimidation / Regard vif)
    WEAK_POKEMON_ABILITY = %i[intimidate keen_eye]
    # List of special wild battle that are actually fishing
    FISHING_BATTLES = %i[normal super mega]
    # List of Roaming Pokemon
    # @return [Array<PFM::Wild_RoamingInfo>]
    attr_reader :roaming_pokemons
    # List of Remaining Pokemon groups
    #
    # [ (grass)[(tag 0)Wild_info, (tag1)Wild_info,...], (tall_grass)[...], ...]
    # @return [Array<Array<PFM::Wild_Info>>]
    attr_reader :remaining_pokemons
    # The fish group information
    # @return [Hash]
    attr_reader :fishing
    # The actual code to determine if the group should be realoaded (Time change)
    # @return [Integer]
    attr_reader :code
    # Create a new Wild_Battle manager
    def initialize
      @roaming_pokemons = []
      @remaining_pokemons = Array.new(MAX_ZONE_COUNT) { [] }
      @forced_wild_battle = false
      @fishing = {}
      @code = 0
    end

    # Reset the wild battle
    def reset
      @remaining_pokemons.each(&:clear)
      @roaming_pokemons.each(&:update)
      @roaming_pokemons.delete_if(&:pokemon_dead?)
      PFM::Wild_RoamingInfo.lock
      # @forced_wild_battle=false
      @fishing.clear
      @fishing[:normal] = []
      @fishing[:super] = []
      @fishing[:mega] = []
      @fishing[:rock] = []
      @fishing[:headbutt] = []
      @fished = false
      @fish_battle = nil
    end

    # Load the groups of Wild Pokemon (map change/ time change)
    def load_groups
      groups = $env.get_current_zone_data.groups
      @code = groups.size
      sw = nil
      groups&.each do |group|
        map_id = group.instance_variable_get(:@map_id) || 0
        if map_id == 0 || $game_map.map_id == map_id
          sw = group.instance_variable_get(:@enable_switch)
          set(*group) if !sw or $game_switches[sw]
          @code = (@code * 2 + sw) if sw && $game_switches[sw]
        end
      end
    end

    # Is a wild battle available ?
    # @return [Boolean]
    def available?
      return false if $scene.is_a?(Scene_Battle)
      return true if @fish_battle
      # Check roaming pokemon
      @roaming_pokemons.each do |roaming_info|
        if roaming_info.appearing?
          PFM::Wild_RoamingInfo.unlock # Allow Roaming pokemon update at the end of the battle
          roaming_info.spotted = true
          init_battle(roaming_info.pokemon)
          return true
        end
      end
      # Check remaining Pokemon
      @forced_wild_battle = false
      var = @remaining_pokemons[$env.get_zone_type]
      return false unless var
      return false unless $actors[0]
      if var[$game_player.terrain_tag].class == Wild_Info
        var = var[$game_player.terrain_tag]
        level = nil
        if $pokemon_party.repel_count > 0
          levels = var.levels.map { |i| i.is_a?(Integer) ? i : i[:level] }
          return false unless levels.any? { |i| i >= $actors[0].level }
        end
        if WEAK_POKEMON_ABILITY.include?($actors[0].ability_db_symbol)
          var.levels.each do |i|
            level = (i.is_a?(Integer) ? i : i[:level])
            return true if (level + 5) >= $actors[0].level
          end
          return rand(100) < 50
        end
        return true
      end
      return false
    end

    # Test if there's any fish battle available and start it if asked.
    # @param rod [Symbol] the kind of rod used to fish : :norma, :super, :mega
    # @param start [Boolean] if the battle should be started
    # @return [Boolean, nil] if there's a battle available
    def any_fish?(rod = :normal, start = false)
      st = $game_player.front_system_tag
      zone_type = (st == 399 ? 6 : (st == 405 ? 7 : 0))
      if $env.can_fish? && @fishing[rod] && @fishing[rod][zone_type]
        if start
          @fish_battle = @fishing[rod][zone_type]
          if FISHING_BATTLES.include?(rod)
            @fished = true
          else
            @fished = false
          end
        else
          return true
        end
      else
        return false
      end
      return nil
    end

    # Test if there's any hidden battle available and start it if asked.
    # @param rod [Symbol] the kind of rod used to fish : :rock, :headbutt
    # @param start [Boolean] if the battle should be started
    # @return [Boolean, nil] if there's a battle available
    def any_hidden_pokemon?(rod = :rock, start = false)
      zone_type = $env.convert_zone_type($game_player.front_system_tag)
      if @fishing[rod] && @fishing[rod][zone_type]
        if start
          @fish_battle = @fishing[rod][zone_type]
          @fished = false
        else
          return true
        end
      else
        return false
      end
      return nil
    end

    # Start a wild battle
    # @overload start_battle(id, level, *args)
    #   @param id [PFM::Pokemon] First Pokemon in the wild battle.
    #   @param level [Object] ignored
    #   @param args [Array<PFM::Pokemon>] other pokemon in the wild battle.
    # @overload start_battle(id, level, *args)
    #   @param id [Integer] id of the Pokemon in the database
    #   @param level [Integer] level of the first Pokemon
    #   @param args [Array<Integer, Integer>] array of id, level of the other Pokemon in the wild battle.
    def start_battle(id, level = 70, *others, battle_id: 1)
      init_battle(id, level, *others)
      setup(battle_id)
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
        id = GameData::Pokemon.get_id(id) if id.is_a?(Symbol)
        @forced_wild_battle = [PFM::Pokemon.new(id, level)]
        0.step(others.size - 1, 2) do |i|
          others[i] = GameData::Pokemon.get_id(others[i]) if others[i].is_a?(Symbol)
          @forced_wild_battle << PFM::Pokemon.new(others[i], others[i + 1])
        end
      end
    end

    # Set the Battle::Info with the right information
    def setup(battle_id = 1)
      # If it was a forced battle
      if @forced_wild_battle
        configure_battle(@forced_wild_battle, battle_id)
        @forced_wild_battle = false
        return
      end
      wi = @fish_battle || @remaining_pokemons[$env.get_zone_type][$game_player.terrain_tag]
      return unless wi
      @troop = $data_troops[1].members
      wi.ids.each_index do |i|
        @troop[i] = RPG::Troop::Member.new unless @troop[i]
        @troop[i].enemy_id = wi.ids[i]
      end
      configure_pokemon(*wi.levels)
      select_pokemon(wi, *wi.chances)
      configure_battle(@wild_battle, battle_id)
      @wild_battle = @fish_battle = nil
    end

    # Hash describing which method to seek to change the Pokemon chances depending on the player's leading Pokemon's talent
    CHANGE_POKEMON_CHANCE = {
      11 => :intimidate_keen_eye,
      7 => :intimidate_keen_eye,
      16 => :cute_charm,
      92 => :magnet_pull,
      5 => :compound_eyes,
      12 => :static,
      33 => :synchronize
    }

    # Configure the Pokemon array for later selection
    # @overload configure_pokemon(*args)
    #   @param args [Array<Integer>] the levels of the Pokemon in the group
    # @overload configure_pokemon(*args)
    #   @param args [Array<Hash>] the array containing the hashes describing the Pokemon in the group
    def configure_pokemon(*args)
      @select_pokemon_chances = Array.new(args.size, 1)
      ability = $actors[0].ability
      @wild_battle = []
      repel_active = $pokemon_party.repel_count > 0
      args.size.times do |i|
        pkmn_id = @troop[i]
        next unless pkmn_id

        pkmn_id = pkmn_id.enemy_id
        if args[i].is_a?(Integer)
          @wild_battle[i] = PFM::Pokemon.new(pkmn_id, args[i])
        else
          arg = args[i]
          arg[:id] = pkmn_id unless arg[:id]
          @wild_battle[i] = PFM::Pokemon.generate_from_hash(arg)
        end
        send(CHANGE_POKEMON_CHANCE[ability], i) if respond_to? CHANGE_POKEMON_CHANCE[ability]
        if @wild_battle[i].level < $actors[0].level
          @select_pokemon_chances[i] *= 0.33 if $actors[0].item_db_symbol == :cleanse_tag
          @select_pokemon_chances[i] = 0 if repel_active
        end
      end
    end

    # Verify chance changing for Intimidate/Keen Eye cases
    def intimidate_keen_eye(i)
      @select_pokemon_chances[i] = 0.5 if (@wild_battle[i].level + 5) < $actors[0].level
    end

    # Verify chance changing for Cute Charm case
    def cute_charm(i)
      @select_pokemon_chances[i] = 1.5 if ($actors[0].gender * @wild_battle[i].gender) == 2
    end

    # Verify chance changing for Magnet Pull case
    def magnet_pull(i)
      @select_pokemon_chances[i] = 1.5 if @wild_battle[i].type_steel?
    end

    # Verify chance changing for Compound Eyes case
    def compound_eyes(i)
      @select_pokemon_chances[i] = 1.5 if @wild_battle[i].item_holding != 0
    end

    # Verify chance changing for Statik case
    def static(i)
      @select_pokemon_chances[i] = 1.5 if @wild_battle[i].type_electric?
    end

    # Verify chance changing for Synchronize case
    def synchronize(i)
      @select_pokemon_chances[i] = 1.5 if @wild_battle[i].nature_id == $actors[0].nature_id
    end

    # Array listing the ids of the talents that change the way the level is calculated
    MaxEcart = [74, 30, 72]

    # Select the Pokemon that will be in the battle
    # @param wi [PFM::Wild_Info] the descriptor of the Wild group
    # @param ecart [Integer] the gap between lowest and highest level
    # @param rareness [Array<Integer>] array containing the initial chance for each Pokemon
    def select_pokemon(wi, ecart, *rareness)
      max_rand = 0
      p rareness
      rareness.each_index do |i|
        @select_pokemon_chances[i] ||= 1
        max_rand += rareness[i] * @select_pokemon_chances[i]
      end
      selected = []
      wi.vs_type.times do |i|
        nb = Random::WildBattle.rand(max_rand.to_i)
        puts "Generated number : #{nb} / #{max_rand.to_i}"
        count = 0
        rareness.each_index do |j|
          count += (rareness[j] * @select_pokemon_chances[j])
          if nb < count
            selected.push(@wild_battle[j].clone)
            break
          end
        end
        selected.push(@wild_battle[rand(@wild_battle.size)].clone) if selected.size <= i
      end
      @wild_battle = []
      wi.vs_type.times do |i|
        @wild_battle.push(selected[i])
        if MaxEcart.include?($actors[0].ability) && rand(100) < 50
          lvl = selected[i].level - ecart / 2 + ecart - 1
        else
          lvl = selected[i].level - ecart / 2 + rand(ecart)
        end
        lvl = 1 if lvl < 1
        selected[i].level = lvl
        selected[i].captured_level = lvl
        selected[i].exp = selected[i].exp_list[lvl]
        selected[i].hp = selected[i].max_hp
      end
    end

    def configure_battle(enemy_arr, battle_id)
      return if (!enemy_arr.is_a? Array) || !enemy_arr || enemy_arr&.empty?

      info = Battle::Logic::BattleInfo.new
      info.add_party(0, *info.player_basic_info)
      info.add_party(1, enemy_arr)
      info.battle_id = battle_id
      info.vs_type = 2 if enemy_arr.size >= 2
      Graphics.freeze
      $scene = Battle::Scene.new(info)
    end

    # Define a group of remaining wild battle
    # @param zone_type [Integer] type of the zone, see $env.get_zone_type to know the id
    # @param tag [Integer] terrain_tag on which the player should be to start a battle with wild Pokemon of this group
    # @param delta_level [Integer] the disparity of the Pokemon levels
    # @param vs_type [Integer] the vs_type the Wild Battle are
    # @param data [Array<Integer, Integer, Integer>, Array<Integer, Hash, Integer>] Array of id, level/informations, chance to see (Pokemon informations)
    def set(zone_type, tag, delta_level, vs_type, *data)
      return if MAX_ZONE_COUNT <= zone_type
      wi = Wild_Info.new
      wi.delta_level = delta_level
      ids = wi.ids
      levels = wi.levels
      chances = wi.chances
      wi.vs_type = vs_type
      if (data.size / 3 * 3) != data.size
        raise ArgumentError, "Wild Pokémon aren't correctly configured"
      end
      0.step(data.size - 1, 3) do |i|
        j = i / 3
        ids[j] = data[i]
        levels[j] = data[i + 1]
        chances[j + 1] = data[i + 2]
      end
      if tag < 8
        @remaining_pokemons[zone_type][tag] = wi
      elsif tag < 11
        @fishing[tag == 8 ? :normal : tag == 9 ? :super : :mega][zone_type] = wi
      else
        @fishing[tag == 11 ? :rock : :headbutt][zone_type] = wi
      end
    end

    # Test if a Pokemon is a roaming Pokemon (Usefull in battle)
    def is_roaming?(pokemon)
      @roaming_pokemons.each do |roaming_info|
        return true if roaming_info.pokemon == pokemon
      end
      return false
    end

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
      @code += 1
      return pokemon
    end

    # Remove a roaming Pokemon from the roaming Pokemon array
    # @param pokemon [PFM::Pokemon] the Pokemon that should be removed
    def remove_roaming_pokemon(pokemon)
      @roaming_pokemons.delete_if { |i| i.pokemon == pokemon }
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
      rate *= 1.5 if FishIncRate.include?($actors[0] ? $actors[0].ability_db_symbol : -1)
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
  end

  class Pokemon_Party
    # The informations about the Wild Pokemon Battle
    # @return [PFM::Wild_Battle]
    attr_accessor :wild_battle
    on_player_initialize(:wild_battle) { @wild_battle = PFM::Wild_Battle.new }
    on_expand_global_variables(:wild_battle) do
      # Variable containing the Wild Pokemon (Remaining & Romaing) information.
      # It's also able to start battle against Wild Pokemon
      $wild_battle = @wild_battle
    end
  end
end
