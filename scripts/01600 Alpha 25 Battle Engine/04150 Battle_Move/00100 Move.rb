module Battle
  # Generic class describing a move
  class Move
    include Hooks
    # @return [Hash{Symbol => Class}] list of the registered moves
    REGISTERED_MOVES = Hash.new(Move)

    # ID of the move in the database
    # @return [Integer]
    attr_reader :id
    # Number of pp the move currently has
    # @return [Integer]
    attr_reader :pp
    # Maximum number of ppg the move currently has
    # @return [Integer]
    attr_reader :ppmax
    # if the move has been used
    # @return [Boolean]
    attr_accessor :used
    # Number of time the move was used consecutively
    # @return [Integer]
    attr_accessor :consecutive_use_count
    # @return [Battle::Logic]
    attr_reader :logic
    # @return [Battle::Scene]
    attr_reader :scene
    # @return [Battle::Move]
    attr_accessor :original
    # Number of damage dealt last time the move was used (to be used with move history)
    # @return [Integer]
    attr_accessor :damage_dealt
    # The original target of the move (to be used with Magic Bounce/Coat)
    # @return [Array<PFM::PokemonBattler>]
    attr_accessor :original_target

    # Create a new move
    # @param db_symbol [Symbol] db_symbol of the move in the database
    # @param pp [Integer] number of pp the move currently has
    # @param ppmax [Integer] maximum number of pp the move currently has
    # @param scene [Battle::Scene] current battle scene
    def initialize(db_symbol, pp, ppmax, scene)
      data = data_move(db_symbol)
      @id = data.id
      @db_symbol = data.db_symbol
      @pp = pp
      @ppmax = ppmax
      @used = false
      @consecutive_use_count = 0
      @effectiveness = 1
      @damage_dealt = 0
      @original_target = []
      @scene = scene
      @logic = scene.logic
      @reloading = false
    end

    # Format move for logging purpose
    # @return [String]
    def to_s
      "<PM:#{name},#{@consecutive_use_count} pp=#{@pp}>"
    end
    alias inspect to_s

    # Clone the move and give a reference to the original one
    def clone
      clone = super
      clone.original ||= self
      raise 'This function looks badly implement, just want to know where it is called'
    end

    # Return the data of the skill
    # @return [Studio::Move]
    def data
      return data_move(@db_symbol || @id)
    end

    # Return the name of the skill
    def name
      return data.name
    end

    # Return the skill description
    # @return [String]
    def description
      return data.description
    end

    # Return the battle engine method of the move
    # @return [Symbol]
    def be_method
      return data.be_method
    end
    alias symbol be_method # BE24

    # Return the text of the PP of the skill
    # @return [String]
    def pp_text
      "#{@pp} / #{@ppmax}"
    end

    # Return the actual base power of the move
    # @return [Integer]
    def power
      data.power
    end
    alias base_power power # BE24

    # Return the text of the power of the skill (for the UI)
    # @return [String]
    def power_text
      power = data.power
      return text_get(11, 12) if power == 0

      return power.to_s
    end

    # Return the current type of the move
    # @return [Integer]
    def type
      data_type(data.type).id
    end

    # Return the current accuracy of the move
    # @return [Integer]
    def accuracy
      data.accuracy
    end

    # Return the accuracy text of the skill (for the UI)
    # @return [String]
    def accuracy_text
      acc = data.accuracy
      return text_get(11, 12) if acc == 0

      return acc.to_s
    end

    # Return the priority of the skill
    # @param user [PFM::PokemonBattler] user for the priority check
    # @return [Integer]
    def priority(user = nil)
      priority = data.priority - Logic::MOVE_PRIORITY_OFFSET # TODO: Check the whole engine to go to -7~+7
      return priority unless user

      logic.each_effects(user) do |e|
        new_priority = e.on_move_priority_change(user, priority, self)
        return new_priority if new_priority
      end

      return priority
    end

    ## Move priority
    def relative_priority
      return priority + Logic::MOVE_PRIORITY_OFFSET
    end

    # Return the chance of effect of the skill
    # @return [Integer]
    def effect_chance
      return data.effect_chance == 0 ? 100 : data.effect_chance
    end

    # Get all the status effect of a move
    # @return [Array<Studio::Move::MoveStatus>]
    def status_effects
      return data.move_status
    end

    # Return the target symbol the skill can aim
    # @return [Symbol]
    def target
      return data.battle_engine_aimed_target
    end

    # Return the critical rate index of the skill
    # @return [Integer]
    def critical_rate
      return data.critical_rate
    end

    # Is the skill affected by gravity
    # @return [Boolean]
    def gravity_affected?
      return data.is_gravity
    end

    # Return the stat stage modifier the skill can apply
    # @return [Array<Studio::Move::BattleStageMod>]
    def battle_stage_mod
      return data.battle_stage_mod
    end

    # Is the skill direct ?
    # @return [Boolean]
    def direct?
      return data.is_direct
    end

    # Tell if the move is a mental move
    # @return [Boolean]
    def mental?
      return data.is_mental
    end

    # Is the skill affected by Mirror Move
    # @return [Boolean]
    def mirror_move_affected?
      return data.is_mirror_move
    end

    # Is the skill blocable by Protect and skill like that ?
    # @return [Boolean]
    def blocable?
      return data.is_blocable
    end

    # Does the skill has recoil ?
    # @return [Boolean]
    def recoil?
      false
    end

    # Returns the recoil factor
    # @return [Integer]
    def recoil_factor
      4
    end

    # Returns the drain factor
    # @return [Integer]
    def drain_factor
      2
    end

    # Is the skill a punching move ?
    # @return [Boolean]
    def punching?
      return data.is_punch
    end

    # Is the skill a sound attack ?
    # @return [Boolean]
    def sound_attack?
      return data.is_sound_attack
    end

    # Is the skill a slicing attack ?
    # @return [Boolean]
    def slicing_attack?
      return data.is_slicing_attack
    end

    # Does the skill unfreeze
    # @return [Boolean]
    def unfreeze?
      return data.is_unfreeze
    end

    # Is the skill a wind attack ?
    # @return [Boolean]
    def wind_attack?
      return data.is_wind
    end

    # Does the skill trigger the king rock
    # @return [Boolean]
    def trigger_king_rock?
      return data.is_king_rock_utility
    end

    # Is the skill snatchable ?
    # @return [Boolean]
    def snatchable?
      return data.is_snatchable
    end

    # Is the skill affected by magic coat ?
    # @return [Boolean]
    def magic_coat_affected?
      return data.is_magic_coat_affected
    end

    # Is the skill physical ?
    # @return [Boolean]
    def physical?
      return data.category == :physical
    end

    # Is the skill special ?
    # @return [Boolean]
    def special?
      return data.category == :special
    end

    # Is the skill status ?
    # @return [Boolean]
    def status?
      return data.category == :status
    end

    # Return the class of the skill (used by the UI)
    # @return [Integer] 1, 2, 3
    def atk_class
      return 2 if special?
      return 3 if status?

      return 1 if physical?
    end

    # Return the symbol of the move in the database
    # @return [Symbol]
    def db_symbol
      return @db_symbol
    end

    # Change the PP
    # @param value [Integer] the new pp value
    def pp=(value)
      @pp = value.to_i.clamp(0, @ppmax)
    end

    # Was the move a critical hit
    # @return [Boolean]
    def critical_hit?
      @critical
    end

    # Was the move super effective ?
    # @return [Boolean]
    def super_effective?
      @effectiveness >= 2
    end

    # Was the move not very effective ?
    # @return [Boolean]
    def not_very_effective?
      @effectiveness > 0 && @effectiveness < 1
    end

    # Tell if the move is a ballistic move
    # @return [Boolean]
    def ballistics?
      return data.is_ballistics
    end

    # Tell if the move is biting move
    # @return [Boolean]
    def bite?
      return data.is_bite
    end

    # Tell if the move is a dance move
    # @return [Boolean]
    def dance?
      return data.is_dance
    end

    # Tell if the move is a pulse move
    # @return [Boolean]
    def pulse?
      return data.is_pulse
    end

    # Tell if the move is a heal move
    # @return [Boolean]
    def heal?
      return data.is_heal
    end

    # Tell if the move is a two turn move
    # @return [Boolean]
    def two_turn?
      return data.is_charge
    end

    # Tell if the move is a powder move
    # @return [Boolean]
    def powder?
      return data.is_powder
    end

    # Tell if the move is a move that can bypass Substitute
    # @return [Boolean]
    def authentic?
      return data.is_authentic
    end

    # Tell if the move is an OHKO move
    # @return [Boolean]
    def ohko?
      return false
    end

    # Tell if the move is a move that switch the user if that hit
    # @return [Boolean]
    def self_user_switch?
      return false
    end

    # Tell if the move is a move that forces target switch
    # @return [Boolean]
    def force_switch?
      return false
    end

    # Is the move doing something before any other moves ?
    # @return [Boolean]
    def pre_attack?
      false
    end

    # Tells if the move hits multiple times
    # @return [Boolean]
    def multi_hit?
      return false
    end

    # Get the effectiveness
    attr_reader :effectiveness

    class << self
      # Retrieve a registered move
      # @param symbol [Symbol] be_method of the move
      # @return [Class<Battle::Move>]
      def [](symbol)
        REGISTERED_MOVES[symbol]
      end

      # Register a move
      # @param symbol [Symbol] be_method of the move
      # @param klass [Class] class of the move
      def register(symbol, klass)
        raise format('%<klass>s is not a "Move" and cannot be registered', klass: klass) unless klass.ancestors.include?(Move)

        REGISTERED_MOVES[symbol] = klass
      end
    end
  end
end
