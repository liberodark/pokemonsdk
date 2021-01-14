module Battle
  # Logic part of Pokemon Battle
  #
  # This class helps to access to the battle information & to process some part of the battle
  class Logic
    # @return [Array<Array>] list of messages to send to an interpreter (AI/Scene)
    attr_reader :messages
    # @return [Array<Hash>] list of the current actions to proccess during the scene
    attr_reader :actions
    # 0 : Victory, 1 : Defeat, 2 : Flee, -1 : undef
    # @return [Integer]
    attr_accessor :battle_result
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
    # @return [Array<Array<Battle::Effects::EffectsHandler>>]
    attr_reader :position_effects
    # Get the evolve requests
    # @return [Array<PFM::PokemonBattler>]
    attr_reader :evolve_request
    # Get the Mega Evolve helper
    # @return [MegaEvolve]
    attr_reader :mega_evolve
    # Create a new Logic instance
    # @param scene [Scene] scene that hold the logic object
    def initialize(scene)
      @scene = scene
      @battle_info = scene.battle_info
      Message.setup(self)
      @messages = []
      # @type [Array<Actions::Base>]
      @actions = []
      @bags = @battle_info.bags
      @battlers = []
      @terrain_effects = Effects::EffectsHandler.new
      @bank_effects = Array.new(@bags.size) { Effects::EffectsHandler.new }
      # @type [Array<Array<Battle::Effects::EffectsHandler>>]
      @position_effects = Array.new(@bags.size) { Array.new(@battle_info.vs_type) { Effects::EffectsHandler.new } }
      # Mega Evolve helper
      @mega_evolve = MegaEvolve.new(scene)
      # TODO: Remove global_states bank_states
      @global_states = {}
      @bank_states = Hash.new({})
      @battle_result = -1
      @switch_request = []
      @evolve_request = []
      $game_temp.battle_turn = 0
    end

    # Safe to_s & inspect
    def to_s
      format('#<%<class>s:%<id>08X>', class: self.class, id: __id__)
    end
    alias inspect to_s

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

    # Add an effect on a position
    # @param effect [Battle::Effects::PositionTiedEffectBase]
    def add_position_effect(effect)
      bank = effect.bank
      position = effect.position
      # Safety code
      @position_effects[bank] ||= []
      @position_effects[bank][position] ||= Effects::EffectsHandler.new
      @position_effects[bank][position].add(effect)
    end

    # Add an effect on a bank
    # @param effect [Battle::Effects::PositionTiedEffectBase]
    def add_bank_effect(effect)
      bank = effect.bank
      @bank_effects[bank] ||= Effects::EffectsHandler.new
      @bank_effects[bank].add(effect)
    end

    # Delete all the dead effect by updating counters & removing them
    def delete_dead_effects
      @terrain_effects.update_counter
      @bank_effects.each(&:update_counter)
      @position_effects.each { |bank| bank.each { |position| position&.update_counter } }
      all_alive_battlers.map(&:effects).each(&:update_counter)
    end
  end
end
