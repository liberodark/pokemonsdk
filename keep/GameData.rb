# Module that hold all the statical data (non-changing through game play) class & helpers
module GameData
  # The base class of any GameData object
  class Base
    # The id of the object
    # @return [Integer] /!\ can be nil if the data was not correctly defined.
    attr_accessor :id
    # The db_symbol of the object
    # @return [Symbol] /!\ can be nil if the data was not properly defined
    attr_accessor :db_symbol
    # Create a new GameData object
    def initialize
      @id = 0
      @db_symbol = :__undef__
    end
  end

  # A module that help to retrieve nature informations
  # @author Nuri Yuri
  module Natures
    # Data holding all the nature info
    @data = []

    module_function

    # Safely returns a nature info
    # @param nature_id [Integer] id of the nature
    # @return [Array<Integer>]
    def [](nature_id)
      return @data[nature_id] if id_valid?(nature_id)
      return @data[0]
    end

    # Return the number of defined natures
    # @return [Integer]
    def size
      return @data.size
    end

    # Return if the Nature ID is valid
    # @return [Boolean]
    def id_valid?(id)
      return id.between?(0, @data.size - 1)
    end

    # Load the natures
    def load
      @data = load_data('Data/PSDK/Natures.rxdata')
    end

    # Return all the natures
    # @return [Array<Array<Integer>>]
    def all
      @data
    end
  end

  # Module that helps you to retrieve safely texts related to Pokemon's Ability
  # @author Nuri Yuri
  module Abilities
    # List of Abilities db_symbols
    @db_symbols = []
    # List of translated ID ability id (psdk_id => gf_id)
    @psdk_id_to_gf_id = []

    module_function

    class Model
      # ID of the ability
      # @type [Integer]
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def name
        return Abilities.name(@id)
      end

      def descr
        return Abilities.descr(@id)
      end

      def db_symbol
        return Abilities.db_symbol(@id)
      end
    end

    # Returns the name of an ability
    # @param id [Integer, Symbol] id of the ability in the database.
    # @return [String] the name of the ability or the name of the first ability.
    # @note The description is fetched from the 5th text file.
    def name(id = Class)
      return super() if id == Class

      id = get_id(id) if id.is_a?(Symbol)
      return text_get(4, @psdk_id_to_gf_id[id]) if id_valid?(id)
      return text_get(4, 0)
    end

    # Returns the description of an ability
    # @param id [Integer, Symbol] id of the ability in the database.
    # @return [String] the description of the ability or the description of the first ability.
    # @note The description is fetched from the 5th text file.
    def descr(id)
      id = get_id(id) if id.is_a?(Symbol)
      return text_get(5, @psdk_id_to_gf_id[id]) if id_valid?(id)
      return text_get(5, 0)
    end

    # Returns the symbol of an ability
    # @param id [Integer] id of the ability in the database
    # @return [Symbol] the db_symbol of the ability
    def db_symbol(id)
      @db_symbols.fetch(id, :__undef__)
    end

    # Find an ability id using symbol
    # @param symbol [Symbol]
    # @return [Integer, nil] nil = not found
    def find_using_symbol(symbol)
      @db_symbols.index(symbol)
    end
    class << self
      alias get_id find_using_symbol
    end

    # Tell if the id is valid
    # @param id [Integer]
    # @return [Boolean]
    def id_valid?(id)
      return id.between?(0, @psdk_id_to_gf_id.size - 1)
    end

    # Load the abilities
    def load
      @psdk_id_to_gf_id = load_data('Data/PSDK/Abilities.rxdata')
      @db_symbols = load_ability_db_symbol
    end

    # Load the ability db_symbol
    # @return [Array<Symbol>]
    def load_ability_db_symbol
      return load_data('Data/PSDK/Abilities_Symbols.rxdata')
    rescue StandardError, LoadError
      require 'plugins/update_db_symbol.rb' unless PSDK_CONFIG.release?
      return load_data('Data/PSDK/Abilities_Symbols.rxdata')
    end

    # Return the psdk_id_to_gf_id array
    # @return [Array<Integer>]
    def psdk_id_to_gf_id
      return @psdk_id_to_gf_id
    end

    # Convert a collection to symbolized collection
    # @param collection [Enumerable]
    # @param keys [Boolean] if hash keys are converted
    # @param values [Boolean] if hash values are converted
    # @return [Enumerable] the collection
    def convert_to_symbols(collection, keys: false, values: false)
      if collection.is_a?(Hash)
        new_collection = {}
        collection.each do |key, value|
          key = db_symbol(key) if keys && key.is_a?(Integer)
          if value.is_a?(Enumerable)
            value = convert_to_symbols(value, keys: keys, values: values)
          elsif values && value.is_a?(Integer)
            value = db_symbol(value)
          end
          new_collection[key] = value
        end
        collection = new_collection
      else
        collection.each_with_index do |value, index|
          if value.is_a?(Enumerable)
            collection[index] = convert_to_symbols(value, keys: keys, values: values)
          elsif value.is_a?(Integer)
            collection[index] = db_symbol(value)
          end
        end
      end
      collection
    end

    # Get the list of Abilities db_symbols
    # @return [Array<Symbol>] the list of Abilities db_symbols
    def db_symbols
      return @db_symbols
    end
  end

  # Module describing a data source and providing basic function to acceed this data source
  #
  # @note All module extended by this need to define `data_filename` as a filename
  module DataSource
    # Constant containing all the data source (for auto loading)
    SOURCES = []

    # Get a data object
    # @param id [Integer, Symbol] ID of the data object in database
    # @return [self]
    def [](id)
      id = get_id(id) if id.is_a?(Symbol)
      id = 0 unless id.is_a?(Integer) && id_valid?(id)
      return @data[id]
    end

    # Safely return the db_symbol of a data object by it's integer ID
    # @param id [Integer] id of the item in the database
    # @return [Symbol]
    def db_symbol(id)
      return id_valid?(id) && @data[id].db_symbol || :__undef__
    end

    # Get id using symbol
    # @param symbol [Symbol]
    # @return [Integer]
    def get_id(symbol)
      return @db_symbol_to_id[symbol]
    end

    # Tell if the item id is valid
    # @param id [Integer]
    # @return [Boolean]
    def id_valid?(id)
      return id.between?(@first_index, @last_index)
    end

    # Load the items
    def load
      # @type [Array<GameData::Base>]
      @data = load_data(data_filename)
      @data.each_with_index { |item, index| item&.id = index }
      const_set(:LAST_ID, @last_index = @data.size - 1)
      # @type [Hash{Symbol => Integer}]
      @db_symbol_to_id = @data[@first_index..@last_index].map { |i| [i.db_symbol || :__bad__, i.id || 0] }.to_h
      @db_symbol_to_id[:__undef__] = 0
      @db_symbol_to_id.default = 0
    end

    # Return all the item
    # @return [Array<self>]
    def all
      return @data
    end

    # Convert a collection to symbolized collection
    # @param collection [Enumerable]
    # @param keys [Boolean] if hash keys are converted
    # @param values [Boolean] if hash values are converted
    # @return [Enumerable] the collection
    # @example Convert an array of integer to db_symbols
    #   convert_to_symbols([1, 2, 3])
    #   # =>
    #   [:sym1, :sym2, :sym3]
    # @example Convert a Hash but only keys
    #   convert_to_symbols({ 1 => 1 }, keys: true)
    #   # =>
    #   { :sym1 => 1 }
    # @example Convert Hash but only values
    #   convert_to_symbols({ 1 => 1 }, values: true)
    #   # =>
    #   { 1 => :sym1 }
    # @example Convert Hash
    #   convert_to_symbols({ 1 => 1 }, keys: true, values: true)
    #   # =>
    #   { :sym1 => :sym1 }
    def convert_to_symbols(collection, keys: false, values: false)
      if collection.is_a?(Hash)
        new_collection = {}
        collection.each do |key, value|
          key = db_symbol(key) if keys && key.is_a?(Integer)
          if value.is_a?(Enumerable)
            value = convert_to_symbols(value, keys: keys, values: values)
          elsif values && value.is_a?(Integer)
            value = db_symbol(value)
          end
          new_collection[key] = value
        end
        collection = new_collection
      else
        collection = collection.map do |value|
          if value.is_a?(Enumerable)
            next convert_to_symbols(value, keys: keys, values: values)
          elsif value.is_a?(Integer)
            next db_symbol(value)
          end
        end
      end
      collection
    end

    class << self
      def extended(klass)
        # We add the data collection to the class
        klass.instance_variable_set(:@data, [])
        # We set the 1st index
        klass.instance_variable_set(:@first_index, 1)
        # We set the last index
        klass.instance_variable_set(:@last_index, 0)
        # Add the new class to sources
        SOURCES << klass
      end
    end
  end

  # Module describing a 2D data source
  module DataSource2D
    include DataSource

    # Get a data Object in a 2D Array
    # @param id [Integer, Symbol] ID of the data
    # @param sub_index [Integer] Secondary index of the data
    # @return [self]
    # @note If the sub_index doesn't exists, sub_index 0 will be returned if existing
    def [](id, sub_index = 0)
      id = get_id(id) if id.is_a?(Symbol)
      return @data.dig(id, sub_index) || @data.dig(id, 0) || @data.dig(0, 0)
    end

    # Safely return the db_symbol of a data Object by its integer ID
    # @param id [Integer] id of the item in the database
    # @return [Symbol]
    def db_symbol(id)
      return id_valid?(id) && @data.dig(id, 0)&.db_symbol || :__undef__
    end

    # Load the items
    def load
      # @type [Array<GameData::Base>]
      @data = load_data(data_filename).freeze
      @data.each_with_index { |item, index| item[0]&.id = index }
      const_set(:LAST_ID, @last_index = @data.size - 1)
      # @type [Hash{Symbol => Integer}]
      @db_symbol_to_id = @data[@first_index..@last_index].map { |i| [i[0].db_symbol || :__bad__, i[0].id || 0] }.to_h
      @db_symbol_to_id[:__undef__] = 0
      @db_symbol_to_id.default = 0
    end

    class << self
      def extended(klass)
        # We add the data collection to the class
        klass.instance_variable_set(:@data, [])
        # We set the 1st index
        klass.instance_variable_set(:@first_index, 1)
        # We set the last index
        klass.instance_variable_set(:@last_index, 0)
        # Add the new class to sources
        DataSource::SOURCES << klass
      end
    end
  end
  # Specific data of a Pokeball item
  # @author Nuri Yuri
  # @deprecated This class is deprecated in .25, please stop using it!
  class BallData < Base
    # Image name of the ball in Graphics/ball/
    # @return [String]
    attr_accessor :img
    # Catch rate of the ball
    # @return [Numeric]
    attr_accessor :catch_rate
    # Special catch informations
    # @return [Hash, nil]
    attr_accessor :special_catch
    # Color of the ball
    # @return [Color, nil]
    attr_accessor :color
  end
  # Specific data of an healing item
  # @author Nuri Yuri
  # @deprecated This class is deprecated in .25, please stop using it!
  class ItemHeal < Base
    # Number of HP healed by the Item
    # @return [Integer] 0 if no hp heal
    attr_accessor :hp
    # Percent of total HP the item heals
    # @return [Integer] 0 if no hp_rate heal
    attr_accessor :hp_rate
    # Number of PP the item heals on ONE move
    # @return [Integer, nil] nil if no pp add
    attr_accessor :pp
    # Number of PP the iteam heals on each moves of the Pokemon
    # @return [Integer, nil] nil if no pp add
    attr_accessor :all_pp
    # Add 1/8 of the max PP of a move (add_pp = 1) or set it to the maximum number possible (add_pp = 2)
    # @return [Integer, nil] nil if no max_pp change
    attr_accessor :add_pp
    # List of states the item heals
    # @return [Array<Integer>, nil] nil if no state heal
    attr_accessor :states
    # Number of loyalty point the item add or remove
    # @return [Integer] nil if no loyalty change
    attr_accessor :loyalty
    # Index of the stat that receive +10 EV (boost_stat < 10) or +1 EV (boost_stat >= 10, index = boost_stat % 10).
    # See GameData::EV to know the index
    # @return [Integer, nil] nil if no ev boost
    attr_accessor :boost_stat
    # Number of level the item gives to the Pokemon
    # @return [Integer, nil] nil if no level up
    attr_accessor :level
    # ID of the battle_stage stat the item boost. 0 = atk, 1 = dfe, 2 = spd, 3 = ats, 4 = dfs, 5 = eva, 6 = acc
    # @return [Integer, nil] nil if no boost
    attr_accessor :battle_boost
  end
  # Miscellaneous Item Data structure
  # @author Nuri Yuri
  # @deprecated This class is deprecated in .25, please stop using it!
  class ItemMisc < Base
    # ID of the common event to call when using this item
    # @return [Integer]
    attr_accessor :event_id
    # Number of step the item repel lower level Pokemon
    # @return [Integer]
    attr_accessor :repel_count
    # ID of the CT if the item teach a skill
    # @return [Integer, nil]
    attr_accessor :ct_id
    # ID of the CS if the item teach a skill
    # @return [Integer, nil]
    attr_accessor :cs_id
    # ID of the skill in the database the item teach to a Pokemon
    # @return [Integer, nil]
    attr_accessor :skill_learn
    # If the item is an evolutive stone
    # @return [Boolean]
    attr_accessor :stone
    # If the item helps the player to flee a wild battle
    # @return [Boolean]
    attr_accessor :flee
    # ID of the Pokemon on which the item can be used
    # @return [Integer, nil]
    attr_accessor :need_user_id
    # ID of the attack class (1 = Physical, 2 = Special, 3 = Status) the item need to *1.1 the power
    # @return [Integer, nil]
    attr_accessor :check_atk_class
    # First possible skill type the item can *1.2 its power
    # @return [Integer, nil]
    attr_accessor :powering_skill_type1
    # Second possible skill type the item can *1.2 its power
    # @return [Integer, nil]
    attr_accessor :powering_skill_type2
    # List of Pokemon ids the item can *2 the power of their physical moves
    # @return [Array<Integer>, nil]
    attr_accessor :need_ids_ph_2
    # List of Pokemon ids the item can *2 the power of their special moves
    # @return [Array<Integer>, nil]
    attr_accessor :need_ids_sp_2
    # List of Pokemon ids the item can *2 the power of their special moves
    # @return [Array<Integer>, nil]
    attr_accessor :need_ids_sp_1_5
    # Accuracy multiplier the item gives to the Pokemon
    # @return [Integer, nil]
    attr_accessor :acc
    # Evade multiplier the item gives to the Pokemon
    # @return [Integer, nil]
    attr_accessor :eva
    # Informations related to the berry
    #
    #   bonus: Array(Integer, Integer, Integer, Integer, Integer, Integer) = list of EV add
    #   type: Integer type id the berry change the skill (natural gift) or reduce the power by two on super effective
    #   power: Integer power of the natural gift move with this berry
    #   time_to_grow: Integer # The time the berry need to grow
    # @return [Hash, nil]
    attr_accessor :berry
  end
  # Item Data structure
  # @author Nuri Yuri
  class Item < Base
    extend DataSource
    # Default icon name
    NO_ICON = 'return'
    # List of get item ME
    ItemGetME = %w[Audio/ME/ROSA_ItemObtained.ogg Audio/ME/ROSA_KeyItemObtained.ogg Audio/ME/ROSA_TMObtained.ogg]
    # Name of the item icon in Graphics/Icons/
    # @return [String]
    attr_accessor :icon
    # Price of the item
    # @return [Integer]
    attr_accessor :price
    # Socket id of the item
    # @return [Integer]
    attr_accessor :socket
    # Sort position in the bag, the lesser the position is, the topper it item is shown
    # @return [Integer]
    attr_accessor :position
    # If the item can be used in Battle
    # @return [Boolean]
    attr_accessor :battle_usable
    # If the item can be used in Map
    # @return [Boolean]
    attr_accessor :map_usable
    # If the item has limited uses (can be thrown)
    # @return [Boolean]
    attr_accessor :limited
    # If the item can be held by a Pokemon
    # @return [Boolean]
    attr_accessor :holdable
    # Power of the item when thrown to an other pokemon
    # @return [Integer]
    attr_accessor :fling_power

    # Get heal related data of the item
    # @return [GameData::ItemHeal, nil]
    def heal_data
      log_error("heal_data called by «#{caller[0]}» is deprecated!")
      return @heal_data
    end

    # Get ball related data of the item
    # @return [GameData::BallData, nil]
    def ball_data
      log_error("ball_data called by «#{caller[0]}» is deprecated!")
      return @ball_data
    end

    # Miscellaneous data of the item
    # @return [GameData::ItemMisc, nil]
    def misc_data
      log_error("misc_data called by «#{caller[0]}» is deprecated!")
      return @misc_data
    end

    # Get the name
    # @return [String]
    def name
      return text_get(12, @id) if Item.id_valid?(@id)

      return text_get(12, 0)
    end
    alias exact_name name

    # Get the plural name
    # @return [String]
    def plural_name
      return ext_text(9001, @id) if Item.id_valid?(@id)

      return ext_text(9001, 0)
    end

    # Get the description
    # @return [String]
    def descr
      return text_get(13, @id) if Item.id_valid?(@id)

      return text_get(13, 0)
    end

    # Get the ME of the item when it's got
    # @return [String]
    def me
      return ItemGetME[2] if socket == 3
      return ItemGetME[1] if socket == 5

      return ItemGetME[0]
    end

    class << self
      # Name of the file containing the data
      def data_filename
        return 'Data/PSDK/ItemData.25.rxdata'
      end

      # Name of the file containing the old data
      def old_data_filename
        return 'Data/PSDK/ItemData.rxdata'
      end
    end
  end
  # Pokemon Data Structure
  # @author Nuri Yuri
  class Pokemon < Base
    class PokemonBase
      # Get the name
      # @return [String]
      attr_reader :name

      # Get the description
      # @return [String]
      attr_reader :descr

      # Get the species
      # @return [String]
      attr_reader :species

      # Get the db_symbol
      # @return [Symbol]
      attr_reader :db_symbol

      # Get the id
      # @return [Integer]
      attr_reader :id

      # Get the forms
      # @return [Array<Pokemon>]
      attr_reader :forms
    end

    # Get the forms
    # @return [Array<Pokemon>]
    def forms
      GameData::Pokemon.all[@id].compact
    end

    extend DataSource2D
    # Height of the Pokemon in metter
    # @return [Numeric]
    attr_accessor :height
    # Weight of the Pokemon in Kg
    # @return [Numeric]
    attr_accessor :weight
    # Regional id of the Pokemon
    # @return [Integer]
    attr_accessor :id_bis
    # First type of the Pokemon
    # @return [Integer]
    attr_accessor :type1
    # Second type of the Pokemon
    # @return [Integer]
    attr_accessor :type2
    # HP statistic of the Pokemon
    # @return [Integer]
    attr_accessor :base_hp
    # ATK statistic of the Pokemon
    # @return [Integer]
    attr_accessor :base_atk
    # DFE statistic of the Pokemon
    # @return [Integer]
    attr_accessor :base_dfe
    # SPD statistic of the Pokemon
    # @return [Integer]
    attr_accessor :base_spd
    # ATS statistic of the Pokemon
    # @return [Integer]
    attr_accessor :base_ats
    # DFS statistic of the Pokemon
    # @return [Integer]
    attr_accessor :base_dfs
    # HP EVs givent by the Pokemon when defeated
    # @return [Integer]
    attr_accessor :ev_hp
    # ATK EVs givent by the Pokemon when defeated
    # @return [Integer]
    attr_accessor :ev_atk
    # DFE EVs givent by the Pokemon when defeated
    # @return [Integer]
    attr_accessor :ev_dfe
    # SPD EVs givent by the Pokemon when defeated
    # @return [Integer]
    attr_accessor :ev_spd
    # ATS EVs givent by the Pokemon when defeated
    # @return [Integer]
    attr_accessor :ev_ats
    # DFS EVs givent by the Pokemon when defeated
    # @return [Integer]
    attr_accessor :ev_dfs
    # List of moves the Pokemon can learn by level.
    #   List formated like this : level_move1, id_move1, level_move2, id_move2, ...
    # @return [Array<Integer, Integer>]
    attr_accessor :move_set
    # List of moves (id in the database) the Pokemon can learn by using HM and TM
    # @return [Array<Integer>]
    attr_accessor :tech_set
    # Level when the Pokemon can naturally evolve
    # @return [Integer, nil]
    attr_accessor :evolution_level
    # ID of the Pokemon after its evolution
    # @return [Integer] 0 = No evolution
    attr_accessor :evolution_id
    # Special evolution informations
    # @return [Array<Hash>, nil]
    attr_accessor :special_evolution
    # Index of the Pokemon exp curve (see ExpList)
    # @return [Integer]
    attr_accessor :exp_type
    # Base experience the Pokemon give when defeated (used in the exp caculation)
    # @return [Integer]
    attr_accessor :base_exp
    # Loyalty the Pokemon has at the begining
    # @return [Integer]
    attr_accessor :base_loyalty
    # Factor used during the catch_rate calculation
    # @return [Integer] 0 = Uncatchable (even with Master Ball)
    attr_accessor :rareness
    # Chance in % the Pokemon has to be a female, if -1 it'll have no gender.
    # @return [Integer]
    attr_accessor :female_rate
    # The two groupes of compatibility for breeding. If it includes 15, there's no compatibility.
    # @return [Array(Integer, Integer)]
    attr_accessor :breed_groupes
    # List of move ID the Pokemon can have after hatching if one of its parent has the move
    # @return [Array<Integer>]
    attr_accessor :breed_moves
    # Number of step before the egg hatch
    # @return [Integer]
    attr_accessor :hatch_step
    # List of items with change (in percent) the Pokemon can have when generated
    #   List formated like this : [id item1, chance item1, id item2, chance item2, ...]
    # @return [Array<Integer, Integer>]
    attr_accessor :items
    # ID of the baby the Pokemon can have while breeding
    # @return [Integer] 0 = no baby
    attr_accessor :baby
    # Current form of the Pokemon
    # @return [Integer] 0 = common form
    attr_accessor :form
    # List of ability id the Pokemon can have [common, rare, ultra rare]
    # @return [Array(Integer, Integer, Integer)]
    attr_accessor :abilities
    # List of moves the Pokemon can learn from a NPC
    # @return [Array<Integer>]
    attr_accessor :master_moves
    # Front offset y of the Pokemon for Summary & Dex UI
    # @return [Integer]
    attr_writer :front_offset_y

    # Create a new GameData::Pokemon object
    def initialize
      super
      @height = 1.60
      @weight = 52
      @id_bis = 0
      @type1 = 1
      @type2 = 1
      @base_hp = @base_atk = @base_dfe = @base_spd = @base_ats = @base_dfs = 1
      @ev_hp = @ev_atk = @ev_dfe = @ev_spd = @ev_ats = @ev_dfs = 0
      @move_set = []
      @tech_set = []
      @evolution_level = 0
      @evolution_id = 0
      @special_evolution = nil
      @exp_type = 1
      @base_exp = 100
      @base_loyalty = 0
      @rareness = 0
      @female_rate = 60
      @abilities = [0, 0, 0]
      @breed_groupes = [15, 15]
      @breed_moves = []
      @master_moves = []
      @hatch_step = 1_000_000_000
      @items = [0, 0, 0, 0]
      @baby = 0
    end

    # Name of the Pokemon
    # @return [String]
    def name
      return text_get(0, id)
    end

    # Description of the Pokemon
    # @return [String]
    def descr
      return text_get(2, id)
    end

    # Species of the Pokemon
    # @return [String]
    def species
      return text_get(1, id)
    end

    # Front offset y of the Pokemon for Summary & Dex UI
    # @return [Integer]
    def front_offset_y
      @front_offset_y || 0
    end

    class << self
      # Name of the file containing the data
      def data_filename
        return 'Data/PSDK/PokemonData.rxdata'
      end

      # Safely return the list of Form of the Pokemon including the regular form (index = 0)
      # @param id [Intger, Symbol] id of the Pokemon in the database
      # @return [Array<GameData::Pokemon>]
      def get_forms(id)
        id = get_id(id) if id.is_a?(Symbol)
        return @data[id] || @data.first
      end

      # Return the list of the zone id where the pokemon spawn
      # @param id [Integer] the id of pokemon
      # @return [Array<Integer>]
      def spawn_zones(id)
        result = []
        each_data_zone do |zone|
          is_here = false
          # TODO: Fix
          zone.groups&.each do |group|
            group.each do |pkm|
              next unless pkm.is_a?(Hash)
              next unless pkm[:id] == id
              result << zone.id
              is_here = true
              break
            end
            break if is_here
          end
        end
        return result
      end
    end
  end
  # Data structure of Pokemon moves
  # @author Nuri Yuri
  class Skill < Base
    extend DataSource
    # ID of the common event called when used on map
    # @return [Integer]
    attr_accessor :map_use
    # Symbol of the method to call in the Battle Engine to perform the move
    # @return [Symbol, nil]
    attr_accessor :be_method
    # Type of the move
    # @return [Integer]
    attr_accessor :type
    # Power of the move
    # @return [Integer]
    attr_accessor :power
    # Accuracy of the move
    # @return [Integer]
    attr_accessor :accuracy
    # Maximum amount of PP the move has when unused
    # @return [Integer]
    attr_accessor :pp_max
    # The Pokemon targeted by the move
    # @return [Symbol]
    attr_accessor :target
    # Kind of move 1 = Physical, 2 = Special, 3 = Status
    # @return [Integer]
    attr_accessor :atk_class
    # Critical rate indicator : 0 => 0, 1 => 6.25%, 2 => 12.5%, 3 => 25%, 4 => 33%, 5 => 50%, 6 => 100%
    # @return [Integer]
    attr_accessor :critical_rate
    # Priority of the move
    # @return [Integer]
    attr_accessor :priority
    # If the move makes conctact.
    # PokeAPI Prose: User touches the target.  This triggers some abilities (e.g., static ability) and
    # items (e.g., sticky-barb item).
    # @return [Boolean]
    attr_accessor :direct
    alias contact direct
    alias contact= direct=
    # If the move is a charging move
    # PokeAPI Prose: This move has a charging turn that can be skipped with a power-herb item.
    # @return [Boolean]
    attr_accessor :charge
    # If the move requires recharging turn
    # PokeAPI Prose : The turn after this move is used, the Pokemon's action is skipped so it can recharge.
    # @return [Boolean]
    attr_accessor :recharge
    # If the move is affected by Detect or Protect
    # PokeAPI Prose : This move will not work if the target has used detect move or protect move this turn.
    # @return [Boolean]
    attr_accessor :blocable
    alias protect blocable
    alias protect= blocable=
    # If the move is affected by Snatch
    # PokeAPI Prose : This move will be stolen if another Pokemon has used snatch move this turn.
    # @return [Boolean]
    attr_accessor :snatchable
    # If the move can be used by Mirror Move
    # PokeAPI Prose : A Pokemon targeted by this move can use mirror-move move to copy it.
    # @return [Boolean]
    attr_accessor :mirror_move
    # If the move is punch based
    # PokeAPI Prose : This move has 1.2x its usual power when used by a Pokemon with iron-fist ability.
    # @return [Boolean]
    attr_accessor :punch
    # If the move is affected by Gravity
    # PokeAPI Prose : This move cannot be used in high gravity move.
    # @return [Boolean]
    attr_accessor :gravity
    # If the move is affected by Magic Coat
    # PokeAPI Prose : This move may be reflected back at the user with magic-coat move or magic-bounce ability.
    # @return [Boolean]
    attr_accessor :magic_coat_affected
    alias reflectable magic_coat_affected
    alias reflectable= magic_coat_affected=
    # If the move unfreeze the opponent Pokemon
    # PokeAPI Prose : This move can be used while frozen to force the Pokemon to defrost.
    # @return [Boolean]
    attr_accessor :unfreeze
    # If the move is a sound attack
    # PokeAPI Prose : Pokemon with soundproof ability are immune to this move.
    # @return [Boolean]
    attr_accessor :sound_attack
    # If the move can reach any target of the specied side/bank
    # PokeAPI Prose : In triple battles, this move can be used on either side to target the farthest away foe Pokemon.
    # @return [Boolean]
    attr_accessor :distance
    # If the move can be blocked by Heal Block
    # PokeAPI Prose : This move is blocked by heal-block move.
    # @return [Boolean]
    attr_accessor :heal
    # If the move ignore the substitute
    # PokeAPI Prose : This move ignores the target's substitute move.
    # @return [Boolean]
    attr_accessor :authentic
    # If the move is a powder move
    # PokeAPI Prose : Pokemon with overcoat ability and grass-type Pokemon are immune to this move.
    # @return [Boolean]
    attr_accessor :powder
    # If the move is bite based
    # PokeAPI Prose : This move has 1.5x its usual power when used by a Pokemon with strong-jaw ability.
    # @return [Boolean]
    attr_accessor :bite
    # If the move is pulse based
    # PokeAPI Prose : This move has 1.5x its usual power when used by a Pokemon with mega-launcher ability.
    # @return [Boolean]
    attr_accessor :pulse
    # If the move is a ballistics move
    # PokeAPI Prose : This move is blocked by bulletproof ability.
    # @return [Boolean]
    attr_accessor :ballistics
    # If the move has mental effect
    # PokeAPI Prose : This move is blocked by aroma-veil ability and cured by mental-herb item.
    # @return [Boolean]
    attr_accessor :mental
    # If the move cannot be used in Fly Battles
    # PokeAPI Prose : This move is unusable during Sky Battles.
    # @return [Boolean]
    attr_accessor :non_sky_battle
    # If the move is a dancing move
    # PokeAPI Prose : This move triggers dancer ability.
    # @return [Boolean]
    attr_accessor :dance
    # If the move triggers King's Rock
    # @return [Boolean]
    attr_accessor :king_rock_utility
    # Chance (in percent) the effect (stat/status) triggers
    # @return [Integer]
    attr_accessor :effect_chance
    # Stat change effect
    # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
    attr_accessor :battle_stage_mod
    # The status effect
    # @return [Integer, nil]
    attr_accessor :status
    # List of moves that works when the Pokemon is asleep
    SleepingAttack = %i[snore sleep_talk]
    # Out of reach moves
    #   OutOfReach[sb_symbol] => oor_type
    OutOfReach = { dig: 1, fly: 2, dive: 3, bounce: 2, phantom_force: 4, shadow_force: 4, sky_drop: 2 }
    # List of move that can hit a Pokemon when he's out of reach
    #   OutOfReach_hit[oor_type] = [move db_symbol list]
    OutOfReach_hit = [
      [], # Nothing
      %i[earthquake fissure magnitude], # Dig
      %i[gust whirlwind thunder swift sky_uppercut twister smack_down hurricane thousand_arrows], # Fly
      %i[surf whirlpool], # Dive
      [], # Phantom force / Shadow Force
      ]
    # List of specific announcement for 2 turn moves
    #   Announce_2turns[db_symbol] = text_id
    Announce_2turns = { dig: 538, fly: 529, dive: 535, bounce: 544,
                        phantom_force: 541, shadow_force: 541, solar_beam: 553,
                        skull_bash: 556, razor_wind: 547, freeze_shock: 866,
                        ice_burn: 869, geomancy: 1213, sky_attack: 550,
                        focus_punch: 1213 }
    # List of Punch moves
    Punching_Moves = %i[dynamic_punch mach_punch hammer_arm focus_punch bullet_punch
                        power_up_punch comet_punch needle_arm fire_punch meteor_mash
                        shadow_punch thunder_punch ice_punch sky_uppercut mega_punch
                        dizzy_punch drain_punch karate_chop]

    # Create a new GameData::Skill object
    def initialize
      super
      @map_use = 0
      @be_method = :s_basic
      @type = 0
      @power = 0
      @accuracy = 0
      @pp_max = 5
      @target = :none
      @atk_class = 2
      @direct = false
      @critical_rate = 0
      @priority = 0
      @blocable = false
      @snatchable = false
      @gravity = false
      @magic_coat_affected = false
      @mirror_move = false
      @unfreeze = false
      @sound_attack = false
      @king_rock_utility = false
      @effect_chance = 0
      @battle_stage_mod = [0, 0, 0, 0, 0, 0, 0, 0]
      @status = 0
      @charge = false
      @recharge = false
      @punch = false
      @distance = false
      @heal = false
      @authentic = false
      @powder = false
      @pulse = false
      @ballistics = false
      @mental = false
      @non_sky_battle = false
      @dance = false
    end

    # Return the name of the move
    # @return [String]
    def name
      GameData::Skill.id_valid?(@id) ? text_get(6, @id) : '???'
    end

    # Is the move a punch move ?
    # @return [Boolean]
    def punching?
      return @punch || Punching_Moves.include?(@db_symbol)
    end

    # Is the move a sleeping attack ?
    # @return [Boolean]
    def sleeping_attack?
      SleepingAttack.include?(db_symbol)
    end

    # Get the out of reach type of the move
    # @return [Integer, nil] nil if not an oor move
    def out_of_reach_type
      return OutOfReach[db_symbol]
    end

    class << self
      # Name of the file containing the skill
      def data_filename
        return 'Data/PSDK/SkillData.rxdata'
      end

      # Safely return the out of reach type of a move
      # @param id [Symbol, Integer] db_symbol or id of the move in the database
      # @return [Integer, nil] nil if not an oor move
      def get_out_of_reach_type(id)
        id = db_symbol(id) if id.is_a?(Integer)
        return OutOfReach[id]
      end

      # Tell if the move can hit de out of reach Pokemon
      # @param oor [Integer] out of reach type
      # @param id [Symbol, Integer] db_symbol or id of the move in the database
      # @return [Boolean]
      def can_hit_out_of_reach?(oor, id)
        return false if oor >= OutOfReach_hit.size || oor < 0

        id = db_symbol(id) if id.is_a?(Integer)
        return OutOfReach_hit[oor].include?(id)
      end

      # Return the id of the 2 turn announce text
      # @param id [Symbol, Integer] db_symbol or id of the move in the database
      # @return [Integer, nil]
      def get_2turns_announce(id)
        id = db_symbol(id) if id.is_a?(Integer)
        return Announce_2turns[id]
      end
    end
  end
  # Type data structure
  # @author Nuri Yuri
  class Type < Base
    extend DataSource
    # Name of the unknown type
    DEFAULT_NAME = '???'
    # ID of the text that gives the type name
    # @return [Integer]
    attr_accessor :text_id
    # Result multiplier when a offensive type hit on this defensive type
    # @return [Array<Numeric>]
    attr_accessor :on_hit_tbl

    # Create a new Type
    # @param text_id [Integer] id of the type name text in the 3rd text file
    # @param on_hit_tbl [Array<Numeric>] table of multiplier when an offensive type hit this defensive type 
    def initialize(text_id, on_hit_tbl)
      super
      @text_id = text_id
      @on_hit_tbl = on_hit_tbl
    end

    # Return the name of the type
    # @return [String]
    def name
      return text_get(3, @text_id) if @text_id >= 0

      return DEFAULT_NAME
    end

    # Return the damage multiplier
    # @param offensive_type_id [Integer] id of the offensive type
    # @return [Numeric]
    def hit_by(offensive_type_id)
      return @on_hit_tbl[offensive_type_id] || 1
    end

    @first_index = 0

    class << self
      # Filename of the file containing the data
      def data_filename
        return 'Data/PSDK/Types.rxdata'
      end
    end
  end
  # Trainer data structure
  # @author Nuri Yuri
  class Trainer < Base
    extend DataSource
    # The value that is multiplied to the last pokemon level to get the money the trainer gives
    # @return [Integer]
    attr_accessor :base_money
    # List of name of the trainers
    # @return [Array<String>]
    attr_accessor :internal_names
    # The battle type 1v1, 2v2, 3v3...
    # @return [Integer]
    attr_accessor :vs_type
    # The name of the battler in Graphics/Battlers
    # @return [String]
    attr_accessor :battler
    # List of Pokemon Hash (PFM::Pokemon.generate_from_hash)
    # @return [Array<Hash>]
    attr_accessor :team
    # ID of the group that holds the event variation of the battle
    # @return [Integer] 0 = no special group
    attr_accessor :special_group
    # Create a new Trainer
    def initialize
      @base_money = 30
      @internal_names = ['Jean']
      @vs_type = 1
      @team = []
      @battler = '001'
      @special_group = 0
    end

    def class_name
      return text_get(29, id || 0)
    end

    @first_index = 0
    class << self
      # Name of the file containing the data
      def data_filename
        return 'Data/PSDK/Trainers.rxdata'
      end

      # Return the trainer class name
      # @param id [Integer] id of the trainer in the database
      # @return [String]
      def class_name(id)
        return text_get(29, id) if id_valid?(id)

        return text_get(29, 0)
      end

      # Get a specific trainer
      # @param id [Integer] ID of the trainer
      # @return [GameData::Trainer]
      def get(id)
        return self[id]
      end
    end
  end
  # Map Zone Data structure
  # @author Nuri Yuri
  class Zone < Base
    extend DataSource
    # ID or list of MAP ID the zone is related to. (RMXP MAP ID !)
    # @return [Integer, Array<Integer>]
    attr_accessor :map_id
    # ID of the worldmap to display when in this zone
    # @return [Integer]
    attr_accessor :worldmap_id
    # Number at the end of the Panel file (Graphics/Windowskins/Panel_{panel_id})
    # @return [Integer] if 0 no panel is shown
    attr_accessor :panel_id
    # X position of the Warp when using Dig, Teleport or Fly
    # @return [Integer, nil] nil if no warp
    attr_accessor :warp_x
    # Y position of the Warp when using Dig, Teleport or Fly
    # @return [Integer, nil] nil if no warp
    attr_accessor :warp_y
    # X position of the player on the World Map
    # @return [Integer, nil]
    attr_accessor :pos_x
    # Y position of the player on the World Map
    # @return [Integer, nil]
    attr_accessor :pos_y
    # If the player can use fly in this zone (otherwise he can use Dig)
    # @return [Boolean]
    attr_accessor :fly_allowed
    # If its not allowed to use fly, dig or teleport in this zone
    # @return [Boolean]
    attr_accessor :warp_dissalowed
    # Unused
    # @return [Array, nil]
    attr_accessor :sub_map
    # ID of the weather in the zone
    # @return [Integer, nil]
    attr_accessor :forced_weather
    # Unused
    # @return [String, nil]
    attr_accessor :description
    # See PFM::Wild_Battle#load_groups
    # @return [Array, nil]
    attr_accessor :groups
    # Create a new GameData::Map object
    # @param map_id [Integer] future value of the attribute
    # @param panel_id [Integer] future value of the attribute
    # @param warp_x [Integer, nil] future value of the attribute
    # @param warp_y [Integer, nil] future value of the attribute
    # @param pos_x [Integer, nil] future value of the attribute
    # @param pos_y [Integer, nil] future value of the attribute
    # @param sub_map [Array, nil] future value of the attribute
    # @param fly_allowed [Boolean] future value of the attribute
    # @param warp_dissalowed [Boolean] future value of the attribute
    # @param forced_weather [Integer] future value of the attribute
    # @param description [String, nil] future value of the attribute
    # @param worldmap_id [Integer, 0] future value of the attribute
    def initialize(map_id, panel_id=0, description=nil, warp_x=nil, warp_y=nil, sub_map=nil, pos_x=nil, pos_y=nil, fly_allowed=true, warp_dissalowed=false,forced_weather=nil, worldmap_id = 0)
      @map_id = map_id
      @worldmap_id = worldmap_id
      @panel_id = panel_id
      @warp_x = warp_x
      @warp_y = warp_y
      @pos_x = pos_x
      @pos_y = pos_y
      @sub_map = sub_map
      @fly_allowed = fly_allowed
      @warp_dissalowed = warp_dissalowed
      @forced_weather = forced_weather
      @description = description
      @groups = []
    end

    # Return the real name of the map (multi-lang compatible)
    # @return [String]
    def map_name
      return @map_name if @map_name
      id = @id || 0
      text_get(10, id)
    end

    # Indicate if a map (by its id) is included in this zone
    # @return [Boolean]
    def map_included?(map_id)
      return @map_id == map_id if(@map_id.is_a?(Numeric))
      @map_id.include?(map_id)
    end

    # Correct name of the attribute
    def warp_disallowed
      @warp_dissalowed
    end

    @first_index = 0
    class << self
      # Name of the file containing the data
      def data_filename
        return 'Data/PSDK/MapData.rxdata'
      end

      alias origina_load_data load_data
      # Load the data properly
      def load_data(filename)
        data = origina_load_data(filename)
        return data if data[0].is_a?(self)

        return data[1] # Old PSDK format
      end

      # Return a zone according to its id
      # @param id [Integer]
      # @return [Zone]
      def get(id)
        return self[id]
      end
    end
  end

  # Backward compatibility for data Loading
  class Map < Zone
  end
  # Data structure of world maps
  # @author Leikt, Nuri Yuri
  class WorldMap < Base
    extend DataSource
    # World map name text id
    # @return [Integer]
    attr_accessor :name_id
    # Wolrd map name file id
    # @return [Integer, String, nil]
    attr_accessor :name_file_id
    # Filename of the image used to display the world map
    # @return [String]
    attr_reader :image
    # Informations on the map
    # @return [Table,Array<WorldMapObject>]
    attr_accessor :data
    # Get the name of the worldmap
    # @return [String]
    def name
      #                                 from Ruby Host                        from csv
      return (@name_file_id.nil? ? text_get(9, @name_id) : ext_text(@name_file_id, @name_id))
    end

    # Create a new GameData::WorldMap
    def initialize(img, name_id, name_file_id)
      @name_id = name_id
      @name_file_id = name_file_id
      self.image = img
    end

    # Modify the image of the zone and resize it
    # @param value [String] the filename
    def image=(value)
      @image = value

      bmp = RPG::Cache.interface(WorldMap.worldmap_image_filename(value))
      max_x = bmp.width / GamePlay::WorldMap::TileSize
      max_y = bmp.height / GamePlay::WorldMap::TileSize
      n_data = Table.new(max_x, max_y)

      if @data
        0.upto([n_data.xsize, @data.xsize].min) do |x|
          0.upto([n_data.ysize, @data.ysize].min) do |y|
            begin
              n_data[x, y] = @data[x, y]
            rescue StandardError
              n_data[x, y] = -1
            end
          end
        end
      end
      @data = n_data
    end

    # Gather the zone list from data. REALLY CONSUMING
    # @return [Array<Integer>]
    def zone_list_from_data
      result = []
      0.upto(@data.xsize - 1) do |x|
        0.upto(@data.ysize - 1) do |y|
          next if @data[x, y] < 0

          result.push @data[x, y] unless result.include?(@data[x, y])
        end
      end
      return result
    end

    @first_index = 0
    class << self
      # Name of the file containing the data
      def data_filename
        return 'Data/PSDK/WorldMaps.rxdata'
      end

      # Get the zones id of this worldmap
      # @param id [Integer] the worldmap id
      # @return [Array<Integer>]
      def zone_list(id)
        result = []
        each_data_zone do |zone|
          result << zone.id if zone.worldmaps.include?(id)
        end
        return result
      end

      # Run the given block on each worldmap id
      # @param block [Proc]
      def each_id(&block)
        @data.each_index(&block)
      end

      # Return a WorldMap
      # @param id [Integer]
      # @return [WorldMap]
      def get(id)
        return self[id]
      end

      # Give the appropriate filename for the worldmap image in Graphics/interface
      # @param filename [String]
      # @return [String]
      def worldmap_image_filename(filename)
        return filename if filename.start_with?('worldmap/worldmaps/')

        return "worldmap/worldmaps/#{filename}"
      end
    end
  end
  class Item
    class << self
      # Fix the data from .24 to .25
      def fix_data
        old_data = load_data(old_data_filename)
        new_data = old_data.map(&:to_new_format)
        save_data(new_data, data_filename)
      end

      alias original_load load
      # Load the items
      def load
        fix_data unless File.exist?(data_filename) || PSDK_CONFIG.release?
        original_load
      end
    end

    # Create a new Item
    # @param id [Integer] ID of the item
    # @param db_symbol [Symbol] db_symbol of the item
    # @param icon [String] Icon of the item
    # @param price [Integer] price of the item
    # @param socket [Integer] socket of the item
    # @param position [Integer] order of the item in the socket
    # @param battle_usable [Boolean] if the item is usable in battle
    # @param map_usable [Boolean] if the item is usable in map
    # @param limited [Boolean] if the item is consumable
    # @param holdable [Boolean] if the item can be held by a Pokemon
    # @param fling_power [Integer] power of the item in fling move
    def initialize(id, db_symbol, icon, price, socket, position, battle_usable, map_usable, limited, holdable, fling_power)
      @id = id.to_i
      @db_symbol = db_symbol.is_a?(Symbol) ? db_symbol : :__undef__
      @icon = icon.to_s
      @price = price.to_i.clamp(0, Float::INFINITY)
      @socket = socket.to_i
      @position = position.to_i
      @battle_usable = battle_usable
      @map_usable = map_usable
      @limited = limited
      @holdable = holdable
      @fling_power = fling_power
    end

    # Get the parameters of the item
    # @return [Array]
    def initialize_params
      [@id, @db_symbol, @icon, @price, @socket, @position, @battle_usable, @map_usable, @limited, @holdable, @fling_power]
    end

    # Convert an item to the new format
    # @return [GameData::Item]
    def to_new_format
      return GameData::Item.new(*initialize_params) unless @heal_data || @ball_data || @misc_data # Regular item no need to convert
      return convert_to_ball_item if @ball_data
      return convert_to_heal_item if @heal_data

      return convert_to_other_kind_item
    end

    private

    # Convert this item to a ball item
    # @return [GameData::BallItem]
    def convert_to_ball_item
      # @type [GameData::BallData]
      data = @ball_data
      return BallItem.new(*initialize_params, data.img, data.catch_rate, data.color || Color.new(255, 0, 0))
    end

    # Convert this item to an other kind of item
    # @return [GameData::EventItem, GameData::FleeingItem, GameData::RepelItem, GameData::StoneItem, GameData::TechItem, GameData::Item]
    def convert_to_other_kind_item
      # @type [GameData::ItemMisc]
      data = @misc_data
      return EventItem.new(*initialize_params, data.event_id) if data.event_id && data.event_id > 0
      return FleeingItem.new(*initialize_params) if data.flee
      return RepelItem.new(*initialize_params, data.repel_count) if data.repel_count && data.repel_count > 0
      return StoneItem.new(*initialize_params) if data.stone
      return TechItem.new(*initialize_params, data.skill_learn, data.cs_id ? true : false) if data.skill_learn

      return GameData::Item.new(*initialize_params)
    end

    # Convert this item to a HealingItem
    # @return [GameData::HealingItem]
    def convert_to_heal_item
      # @type [GameData::ItemHeal]
      data = @heal_data
      loyalty = -data.loyalty.to_i
      if data.hp && data.hp > 0
        return StatusConstantHealItem.new(*initialize_params, loyalty, data.hp, data.states) if data.states

        return ConstantHealItem.new(*initialize_params, loyalty, data.hp)
      elsif data.hp_rate && data.hp_rate > 0
        return StatusRateHealItem.new(*initialize_params, loyalty, data.hp_rate / 100.0, data.states) if data.states

        return RateHealItem.new(*initialize_params, loyalty, data.hp_rate / 100.0)
      end
      return StatusHealItem.new(*initialize_params, loyalty, data.states) if data.states
      return convert_to_battle_boost_item(loyalty, data.battle_boost) if data.battle_boost
      return convert_to_ev_boost_item(loyalty, data.boost_stat) if data.boost_stat
      return AllPPHealItem.new(*initialize_params, loyalty, data.all_pp) if data.all_pp
      return PPHealItem.new(*initialize_params, loyalty, data.pp) if data.pp
      return PPIncreaseItem.new(*initialize_params, loyalty, data.add_pp == 2) if data.add_pp
      return LevelIncreaseItem.new(*initialize_params, loyalty, data.level) if data.level

      return HealingItem.new(*initialize_params, loyalty)
    end

    # Convert this item to a StatBoostItem
    # @param loyalty [Integer] loyalty_malus
    # @param boost [Integer] kind of boost
    # @return [StatBoostItem]
    def convert_to_battle_boost_item(loyalty, boost)
      return StatBoostItem.new(*initialize_params, loyalty, boost % 7, boost / 7 + 1)
    end

    # Convert this item to a EVBoostItem
    # @param loyalty [Integer] loyalty_malus
    # @param boost [Integer] kind of boost
    # @return [EVBoostItem]
    def convert_to_ev_boost_item(loyalty, boost)
      return EVBoostItem.new(*initialize_params, loyalty, boost % 10, boost >= 10 ? 10 : 1)
    end
  end
  # Item that describe the kind of item that calls an event in map
  class EventItem < Item
    # Get the ID of the event to call
    # @return [Integer]
    attr_reader :event_id
    # Create a new event item
    # @param initialize_params [Array] params to create the Item object
    # @param event_id [Integer] ID of the event to call
    def initialize(*initialize_params, event_id)
      super(*initialize_params)
      @event_id = event_id.to_i.clamp(1, Float::INFINITY)
    end
  end
  # Kind of item allowing to flee wild battles
  class FleeingItem < Item
  end
  # Items that repels Pokemon for a certain amount of steps
  class RepelItem < Item
    # Get the number of steps this item repels
    # @return [Integer]
    attr_reader :repel_count

    # Create a new TechItem
    # @param initialize_params [Array] params to create the Item object
    # @param repel_count [Integer] number of steps this item repels
    def initialize(*initialize_params, repel_count)
      super(*initialize_params)
      @repel_count = repel_count.to_i.clamp(1, Float::INFINITY)
    end
  end
  # Item that describe an item that is used as a Stone on Pokemon
  class StoneItem < Item
  end
  # Kind of item that allows the Pokemon to learn a move
  class TechItem < Item
    # HM/TM text
    HM_TM_TEXT = '%s %s'
    # Get the ID of the move it teach
    # @return [Integer]
    attr_reader :move_learnt
    # Get if the item is a Hidden Move or not
    # @return [Boolean]
    attr_reader :is_hm
    # Create a new TechItem
    # @param initialize_params [Array] params to create the Item object
    # @param move_learnt [Integer] ID of the move it teach
    # @param is_hm [Boolean] if the item is an Hidden Move
    def initialize(*initialize_params, move_learnt, is_hm)
      super(*initialize_params)
      @move_learnt = move_learnt.to_i.clamp(1, Float::INFINITY)
      @is_hm = is_hm
    end

    # Get the db_symbol of the move it teaches
    # @return [Symbol]
    def move_db_symbol
      GameData::Skill.db_symbol(@move_learnt)
    end

    # Get the exact name of the item
    # @return [String]
    def exact_name
      return format(HM_TM_TEXT, name, Skill[move_learnt].name)
    end
  end
  # Item that allows to catch Pokemon in battle
  class BallItem < Item
    # Get the image of the ball
    # @return [String]
    attr_reader :img
    # Get the rate of the ball in worse conditions
    # @return [Integer, Float]
    attr_reader :catch_rate
    # Get the color of the ball
    # @return [Color]
    attr_reader :color
    # Create a new TechItem
    # @param initialize_params [Array] params to create the Item object
    # @param img [String] image of the ball
    # @param catch_rate [Integer] rate of the ball in worse conditions
    # @param color [Color] color of the ball
    def initialize(*initialize_params, img, catch_rate, color)
      super(*initialize_params)
      @img = img.to_s
      @catch_rate = catch_rate
      @color = color
    end
  end
  # All items that heals Pokemon
  class HealingItem < Item
    # Get the loyalty malus
    # @return [Integer]
    attr_reader :loyalty_malus
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    def initialize(*initialize_params, loyalty_malus)
      super(*initialize_params)
      @loyalty_malus = loyalty_malus.to_i
    end
  end
  # Item that heals a constant amount of hp
  class ConstantHealItem < HealingItem
    # Get the number of hp the item heals
    # @return [Integer]
    attr_reader :hp_count
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param hp_count [Integer] number of hp it heals
    def initialize(*initialize_params, loyalty_malus, hp_count)
      super(*initialize_params, loyalty_malus)
      @hp_count = hp_count.to_i
    end
  end
  # Item that increase the level of the Pokemon
  class LevelIncreaseItem < HealingItem
    # Get the number of level this item increase
    # @return [Integer]
    attr_reader :level_count
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param level_count [Integer] number of level this item increase
    def initialize(*initialize_params, loyalty_malus, level_count)
      super(*initialize_params, loyalty_malus)
      @level_count = level_count.to_i
    end
  end
  # Item that heals a certain amount of PP of a single move
  class PPHealItem < HealingItem
    # Get the number of PP of the move that gets healed
    # @return [Integer]
    attr_reader :pp_count
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param pp_count [Integer] number of PP of the move that gets healed
    def initialize(*initialize_params, loyalty_malus, pp_count)
      super(*initialize_params, loyalty_malus)
      @pp_count = pp_count.to_i
    end
  end
  # Item that increase the PP of a move
  class PPIncreaseItem < HealingItem
    # Tell if this item sets the PP to the max possible amount
    # @return [Boolean]
    attr_reader :max
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param max [Boolean] if this item sets the PP to the max possible amount
    def initialize(*initialize_params, loyalty_malus, max)
      super(*initialize_params, loyalty_malus)
      @max = max
    end
  end
  # Item that heals a rate (0~100% using a number between 0 & 1) of hp
  class RateHealItem < HealingItem
    # Get the rate of hp this item can heal
    # @return [Float]
    attr_reader :hp_rate
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param hp_rate [Float] rate of hp this item can heal
    def initialize(*initialize_params, loyalty_malus, hp_rate)
      super(*initialize_params, loyalty_malus)
      @hp_rate = hp_rate.to_f.clamp(0, 1)
    end
  end
  # Item that boost a specific stat of a Pokemon in Battle
  class StatBoostItem < HealingItem
    # Get the index of the stat too boost (see: GameData::Stages)
    # @return [Integer]
    attr_reader :stat_index
    # Get the power of the stat to boost
    # @return [Integer]
    attr_reader :count
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param stat_index [Integer] index of the stat too boost (see: GameData::Stages)
    # @param count [Integer] power of the stat to boost
    def initialize(*initialize_params, loyalty_malus, stat_index, count)
      super(*initialize_params, loyalty_malus)
      @stat_index = stat_index.to_i
      @count = count.to_i
    end
  end
  # Item that heals status
  class StatusHealItem < HealingItem
    # Get the list of states the item heals
    # @return [Array<Integer>]
    attr_accessor :status_list
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param status_list [Array<Integer>]
    def initialize(*initialize_params, loyalty_malus, status_list)
      super(*initialize_params, loyalty_malus)
      @status_list = status_list
    end
  end
  # Item that heals a certain amount of PP of all moves
  class AllPPHealItem < PPHealItem
  end
  # Item that boost an EV stat of a Pokemon
  class EVBoostItem < StatBoostItem
  end
  # Item that heals a constant amount of hp and heals status as well
  class StatusConstantHealItem < ConstantHealItem
    # Get the list of states the item heals
    # @return [Array<Integer>]
    attr_accessor :status_list
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param hp_count [Integer] number of hp it heals
    # @param status_list [Array<Integer>]
    def initialize(*initialize_params, loyalty_malus, hp_count, status_list)
      super(*initialize_params, loyalty_malus, hp_count)
      @status_list = status_list
    end
  end
  # Item that heals a rate amount of hp and heals status as well
  class StatusRateHealItem < RateHealItem
    # Get the list of states the item heals
    # @return [Array<Integer>]
    attr_accessor :status_list
    # Create a new HealingItem
    # @param initialize_params [Array] params to create the Item object
    # @param loyalty_malus [Integer] power of the loyalty malus
    # @param hp_rate [Float] rate of hp this item can heal
    # @param status_list [Array<Integer>]
    def initialize(*initialize_params, loyalty_malus, hp_rate, status_list)
      super(*initialize_params, loyalty_malus, hp_rate)
      @status_list = status_list
    end
  end
  # Data containing all the information about a specific quest
  class Quest < Base
    # If the quest is a primary quest
    # @return [Boolean]
    attr_accessor :primary
    # List of Objectives to complete the quest
    # @return [Array<Objective>]
    attr_accessor :objectives
    # List of Earnings given
    # @return [Array<Earning>]
    attr_accessor :earnings

    # Get the name of the quest
    # @return [String]
    def name
      text_get(45, @id)
    end

    # Get the description of the quest
    # @return [String]
    def descr
      text_get(46, @id)
    end

    # Data containing the specific information about an objective
    class Objective
      # Name of the method that validate the objective in PFM::Quests
      # @return [Symbol]
      attr_accessor :test_method_name
      # Argument for the objective validation method & text format method
      # @return [Array]
      attr_accessor :test_method_args
      # Name of the method that formats the text for the objective list
      # @return [Symbol]
      attr_accessor :text_format_method_name
      # Boolean telling if it's hidden or not by default
      # @return [Boolean]
      attr_accessor :hidden_by_default

      # Create a new objective
      # @param test_method_name [Symbol]
      # @param test_method_args [Array]
      # @param text_format_method_name [Symbol]
      # @param hidden_by_default [Boolean]
      def initialize(test_method_name, test_method_args, text_format_method_name, hidden_by_default = false)
        @test_method_name = test_method_name
        @test_method_args = test_method_args
        @text_format_method_name = text_format_method_name
        @hidden_by_default = hidden_by_default
      end
    end
    # Data containing the specific information about the earning
    class Earning
      # Name of the method called in PFM::Quests when the earning is obtained
      # @return [Symbol]
      attr_accessor :give_method_name
      # Name of the method used to format the text of the earning
      # @return [Symbol]
      attr_accessor :text_format_method_name
      # Argument sent to the give & text format method
      # @return [Array]
      attr_accessor :give_args

      # Create a new earning
      # @param give_method_name [Symbol]
      # @param give_args [Array]
      # @param text_format_method_name [Symbol]
      def initialize(give_method_name, give_args, text_format_method_name)
        @give_method_name = give_method_name
        @give_args = give_args
        @text_format_method_name = text_format_method_name
      end
    end

    # Function that converts the current quest to the new format
    def convert_to_new_format
      return if objectives.is_a?(Array)

      objs = @objectives = []
      old_earnings = @earnings
      earns = @earnings = []
      # Convert speak to
      @speak_to&.each_with_index do |name, index|
        objs << Objective.new(:objective_speak_to, [index, name], :text_speak_to)
      end
      # Convert items
      @items&.each_with_index do |item_id, index|
        amount = @item_amount[index] || 1
        objs << Objective.new(:objective_obtain_item, [item_id, amount], :text_obtain_item)
      end
      # Convert see pokemon
      @see_pokemon&.each do |pokemon_id|
        objs << Objective.new(:objective_see_pokemon, [pokemon_id], :text_see_pokemon)
      end
      # Convert beat pokemon
      @beat_pokemon&.each_with_index do |pokemon_id, index|
        amount = @beat_pokemon_amount[index] || 1
        objs << Objective.new(:objective_beat_pokemon, [pokemon_id, amount], :text_beat_pokemon)
      end
      # Convert catch pokemon
      @catch_pokemon&.each_with_index do |pokemon_id, index|
        amount = @catch_pokemon_amount[index] || 1
        objs << Objective.new(:objective_catch_pokemon, [pokemon_id, amount], :text_catch_pokemon)
      end
      # Convert beat_npc
      @beat_npc&.each_with_index do |name, index|
        amount = @beat_npc_amount[index]
        objs << Objective.new(:objective_beat_npc, [index, name, amount], :text_beat_npc)
      end
      # Convert get egg
      objs << Objective.new(:objective_obtain_egg, [@get_egg_amount], :text_obtain_egg) if @get_egg_amount
      objs << Objective.new(:objective_hatch_egg, [nil, @hatch_egg_amount], :text_hatch_egg) if @hatch_egg_amount
      # Convert earnings
      old_earnings.each do |earning|
        next earns << earning if earning.is_a?(Earning)
        next earns << Earning.new(:earning_money, [earning[:money]], :text_earn_money) if earning[:money]

        earns << Earning.new(:earning_item, [earning[:item], earning[:item_amount]], :text_earn_item)
      end
    end

    class << self
      # All the quests
      # @type [Array<GameData::Quest>]
      @data = []

      # Tell if the quest ID is valid
      # @param id [Integer]
      # @return [Boolean]
      def id_valid?(id)
        return id.between?(0, @data.size - 1)
      end

      # Retrieve a specific quest
      # @param id [Integer]
      # @return [GameData::Quest]
      def [](id)
        return @data[id] if id_valid?(id)

        return @data.first
      end

      # Get all the quests
      # @return [Array<GameData::Quest>]
      def all
        return @data
      end

      # Load the quests
      def load
        # @type [GameData::Quest]
        @data = load_data('Data/PSDK/Quests.rxdata')
        @data.each(&:convert_to_new_format)
        @data.each_with_index do |quest, id|
          quest.id = id
        end
      end
    end
  end
end

module GameData
  module_function

  def load
    # Load natures
    GameData::Natures.load
    # Load association abilityID -> TextID
    GameData::Abilities.load
    # Load all data sources
    GameData::DataSource::SOURCES.each(&:load)
    # Load Maplinks
    $game_data_maplinks = load_data('Data/PSDK/Maplinks.rxdata')
    # Load SystemTags
    $data_system_tags = load_data('Data/PSDK/SystemTags.rxdata')
    # Load Quests
    GameData::Quest.load
  end
end
