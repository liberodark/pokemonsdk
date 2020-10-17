module Battle
  # Logic part of Pokemon Battle
  #
  # This class helps to access to the battle information & to process some part of the battle
  class Logic
    # @return [Array<Array>] list of messages to send to an interpreter (AI/Scene)
    attr_reader :messages
    # @return [Array<Hash>] list of the current actions to proccess during the scene
    attr_reader :actions
    # @return [Integer] 0 : Victory, 1 : Defeat, 2 : Flee, -1 : undef
    attr_reader :battle_result
    # @return [Array<Array<PFM::Bag>>] bags of each banks
    attr_reader :bags
    # @return [Battle::Logic::BattleInfo]
    attr_reader :battle_info
    # Get the terrain effects
    # @return [Effects::EffectsHandler]
    attr_reader :terrain_effects
    # Get the bank effects
    # @return [Array<Effects::EffectsHandler>]
    attr_reader :bank_effects
    # Get the position effects
    # @return [Array<Array<Effects::EffectsHandler>>]
    attr_reader :position_effects
    # Create a new Logic instance
    # @param battle_scene [Scene] scene that hold the logic object
    def initialize(battle_scene)
      @battle_scene = battle_scene
      @battle_info = battle_scene.battle_info
      Message.setup(self)
      @messages = []
      # @type [Array<Hash>]
      @actions = []
      @bags = @battle_info.bags
      @battlers = []
      @terrain_effects = Effects::EffectsHandler.new
      @bank_effects = Array.new(@bags.size) { Effects::EffectsHandler.new }
      @position_effects = Array.new(@bags.size) { Array.new(@battle_info.vs_type) { Effects::EffectsHandler.new } }
      # TODO: Remove global_states bank_states
      @global_states = {}
      @bank_states = Hash.new({})
      @battle_result = -1
      @switch_request = []
      @evolve_request = []
      $game_temp.battle_turn = 0
    end

    # Return the number of bank in the current battle
    # @return [Integer]
    def bank_count
      return @battlers.size
    end

    # Tell if the battle can continue
    # @return [Boolean]
    def can_battle_continue?
      return false if @battle_result >= 0
      banks_that_can_fight = []
      @battlers.each_with_index do |battler_bank, bank|
        battler_bank.each do |battler|
          break(banks_that_can_fight << bank) if battler&.can_fight?
        end
      end
      # It's a victory if the player still have a Pokemon on its bank
      if banks_that_can_fight.size <= 1
        @battle_result = banks_that_can_fight.include?(0) ? 0 : 1
        return false
      end
      return true
    end

    # Load the RNG for the battle logic
    # @param seeds [Hash] seeds for the RNG
    def load_rng(seeds = Hash.new(Random.new_seed))
      @move_damage_rng = Random.new(seeds[:move_damage_rng])
      @move_critical_rng = Random.new(seeds[:move_critical_rng])
      @move_accuracy_rng = Random.new(seeds[:move_accuracy_rng])
    end

    # Get the current RNG Seeds
    # @return [Hash{ Symbol => Integer }]
    def rng_seeds
      {
        move_damage_rng: @move_damage_rng.seed,
        move_critical_rng: @move_critical_rng.seed,
        move_accuracy_rng: @move_accuracy_rng.seed
      }
    end

    # Execute a block on each effect depending on what to select as effect
    # @param pokemons [Array<PFM::PokemonBattler>] list of battlers we want to see their effect executed
    # @yieldparam [Effects::EffectBase]
    # @return [Symbol, Integer, nil] the first block return that was a symbol
    def each_effects(*pokemons)
      # Define the proc that will ensure effects are properly called and stop the function if the result is a Symbol
      yielder = proc do |e|
        r = yield(e)
        return r if r.is_a?(Symbol)
      end
      # Terrain effect
      @terrain_effects.each(&yielder)
      # Effect on Pokemon & their position
      pokemons.each do |pokemon|
        next unless pokemon
        pokemon.effects.each(&yielder)
        @position_effects[pokemon.bank][pokemon.position]&.each(&yielder)
      end
      # Effect on banks
      pokemons.compact.map(&:bank).uniq.each { |bank| @bank_effects[bank]&.each(&yielder) }
      return nil
    end
  end
end
