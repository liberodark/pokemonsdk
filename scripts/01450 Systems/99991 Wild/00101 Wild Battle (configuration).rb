module PFM
  class Wild_Battle
    # Hash describing which method to seek to change the Pokemon chances depending on the player's leading Pokemon's talent
    CHANGE_POKEMON_CHANCE = {
      keen_eye: :rate_intimidate_keen_eye,
      intimidate: :rate_intimidate_keen_eye,
      cute_charm: :rate_cute_charm,
      magnet_pull: :rate_magnet_pull,
      compound_eyes: :rate_compound_eyes,
      super_luck: :rate_compound_eyes,
      static: :rate_static,
      lightning_rod: :rate_static,
      flash_fire: :rate_flash_fire,
      synchronize: :rate_synchronize,
      storm_drain: :rate_storm_drain,
      harvest: :rate_harvest
    }

    private

    # Configure the creature array for later selection
    # @param creatures [Array<PFM::Pokemon>]
    # @return [Array<Array(PFM::Pokemon, Float)>] all creatures with their rate to get selected
    def configure_creature(creatures)
      main_creature = $actors[0]
      ability = creature_ability
      repel_active = PFM.game_state.repel_count > 0
      return creatures.map do |creature|
        rate = 1
        rate = send(CHANGE_POKEMON_CHANCE[ability], creature, main_creature) if respond_to?(CHANGE_POKEMON_CHANCE[ability] || :__undef__, true)
        # Cleanse tag & repel
        if creature.level < main_creature.level
          rate *= 0.33 if main_creature.item_db_symbol == :cleanse_tag
          rate = 0 if repel_active
        end
        next [creature, rate]
      end
    end

    # Get rate for Intimidate/Keen Eye cases
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_intimidate_keen_eye(creature, main_creature)
      return (creature.level + 5) < main_creature.level ? 0.5 : 1
    end

    # Get rate for Cute Charm case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_cute_charm(creature, main_creature)
      return (creature.gender * main_creature.gender) == 2 ? 1.5 : 1
    end

    # Get rate for Magnet Pull case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_magnet_pull(creature, main_creature)
      return creature.type_steel? ? 1.5 : 1
    end

    # Get rate for Compound Eyes case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_compound_eyes(creature, main_creature)
      return creature.item_db_symbol != :__undef__ ? 1.5 : 1
    end

    # Get rate for Statik case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_static(creature, main_creature)
      return creature.type_electric? ? 1.5 : 1
    end

    # Get rate for Storm Drain case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_storm_drain(creature, main_creature)
      return creature.type_water? ? 1.5 : 1
    end

    # Get rate for Flash Fire case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_flash_fire(creature, main_creature)
      return creature.type_fire? ? 1.5 : 1
    end

    # Get rate for Harvest case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_harvest(creature, main_creature)
      return creature.type_grass? ? 1.5 : 1
    end

    # Get rate for Synchronize case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_synchronize(creature, main_creature)
      return creature.nature_id == main_creature.nature_id ? 1.5 : 1
    end

    # Select the creatures that will be in the battle
    # @param group [Studio::Group] the descriptor of the Wild group
    # @param creature_to_select [Array<Array(PFM::Pokemon, Float)>] list of Pokemon to select with their rates
    # @return [Array<PFM::Pokemon>]
    def select_creature(group, creature_to_select)
      encounters = group.encounters
      # @note i % wi.ids.size is there to prevent bugs due to double battle that basically double the pokemons to ensure we can get twice the same
      #       creature
      # @type [Array<Array(PFM::Pokemon, Float)>]
      real_rareness = creature_to_select.map.with_index { |arr, i| [arr.first, arr.last * encounters[i % encounters.size].encounter_rate] }
      # @type [Array<Float>]
      reduced_rareness = real_rareness.reduce([]) { |acc, curr| acc << (curr.last + (acc.last || 0)) }
      max_rand = reduced_rareness.last
      # This reducer prevents to select the exact same Creature twice
      return (group.is_double_battle ? 2 : 1).times.reduce([]) do |acc, _|
        nb = Random::WILD_BATTLE.rand(max_rand.to_i)
        index = reduced_rareness.find_index { |i| i > nb } || real_rareness.size - 1
        creature = real_rareness[index].first
        redo if acc.include?(creature)
        acc << creature
      end
    end

    # Configure the wild battle
    # @param enemy_arr [Array<PFM::Pokemon>]
    # @param battle_id [Integer] ID of the events to load for battle scenario
    # @return [Battle::Logic::BattleInfo]
    def configure_battle(enemy_arr, battle_id)
      return if (!enemy_arr.is_a? Array) || !enemy_arr || enemy_arr&.empty?

      has_roaming = enemy_arr.any? { |pokemon| roaming?(pokemon) }
      info = Battle::Logic::BattleInfo.new
      info.add_party(0, *info.player_basic_info)
      info.add_party(1, enemy_arr, nil, nil, nil, nil, nil, has_roaming ? -1 : 0)
      info.battle_id = battle_id
      info.fishing = !@fish_battle.nil?
      info.vs_type = 2 if enemy_arr.size >= 2
      return info
    end
  end
end
