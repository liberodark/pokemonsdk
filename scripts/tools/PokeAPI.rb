# This script purpose is to update DATA according to the PokeAPI references
#
# To get access to this call :
#   ScriptLoader.load_tool('PokeAPI')
#
# To update the data according to PokeAPI use
#   PokeAPI.update(path, version_group_id)
# Where path is the location of all the PokeAPI csv files
# and version_group_id is the version you want for data
module PokeAPI
  module_function

  # Update the PSDK data according to the PokeAPI files
  # @param path [String] folder containing all the PokeAPI csv files
  # @param version_groupd_id [Integer] version on which you want the data
  def update(path, version_group_id)
    Version.load(path)
    Type.load(path)
    MoveChangeLog.load(path)
    Move.load(path)
    process_moves(version_group_id)
  end

  def process_moves(version_group_id)
    # @type [Hash{ Integer => Move }]
    move_by_psdk_id = Move.all.map { |move| [move.psdk_id, move.updated_to(version_group_id)] }.to_h
    GameData::Skill.all.each do |skill|
      move = move_by_psdk_id[skill.id]
      next unless move

      skill.type = move.psdk_type
      skill.power = move.power
      skill.pp_max = move.pp
      skill.accuracy = move.accuracy
      skill.priority = move.psdk_priority
      # skill.target = ...move.target_id
      skill.atk_class = move.atk_class
      # move.effect => convert to PSDK effect
      # skill.effect_chance = move.effect_chance # => inaccurate
    end

    File.write('Data/PSDK/SkillData.rxdata.yml', YAML.dump(GameData::Skill.all))
  end

  class Version
    attr_reader :id
    attr_reader :version_group_id
    attr_reader :identifier
    def initialize(row, indexes)
      @id = row[indexes[0]].to_i
      @version_group_id = row[indexes[1]].to_i
      @identifier = row[indexes[2]]
    end

    class << self
      # @return [Array<Version>]
      def load(path)
        rows = CSV.read(File.join(path, 'versions.csv'))
        header = rows.shift
        indexes = [
          header.index('id') || 0,
          header.index('version_group_id') || 0,
          header.index('identifier') || 0
        ]
        return @all = rows.map { |row| Version.new(row, indexes) }
      end

      # All the loaded versions
      # @return [Array<Version>]
      attr_accessor :all
    end
  end

  class MoveChangeLog
    attr_reader :id
    attr_reader :changed_in_version_group_id
    attr_reader :type_id
    attr_reader :power
    attr_reader :pp
    attr_reader :accuracy
    attr_reader :priority
    attr_reader :target_id
    attr_reader :effect_id
    attr_reader :effect_chance
    def initialize(row, indexes)
      @id = row[indexes[0]].to_i
      @changed_in_version_group_id = row[indexes[1]].to_i
      @type_id = row[indexes[2]]&.to_i
      @power = row[indexes[3]]&.to_i
      @pp = row[indexes[4]]&.to_i
      @accuracy = row[indexes[5]]&.to_i
      @priority = row[indexes[6]]&.to_i
      @target_id = row[indexes[7]]&.to_i
      @effect_id = row[indexes[8]]&.to_i
      @effect_chance = row[indexes[9]]&.to_i
    end

    class << self
      # @return [Array<MoveChangeLog>]
      def load(path)
        rows = CSV.read(File.join(path, 'move_changelog.csv'))
        header = rows.shift
        indexes = [
          header.index('id') || 0,
          header.index('changed_in_version_group_id') || 0,
          header.index('type_id') || 0,
          header.index('power') || 0,
          header.index('pp') || 0,
          header.index('accuracy') || 0,
          header.index('priority') || 0,
          header.index('target_id') || 0,
          header.index('effect_id') || 0,
          header.index('effect_chance') || 0
        ]
        return @all = rows.map { |row| MoveChangeLog.new(row, indexes) }
      end

      # All the loaded move changelog
      # @return [Array<MoveChangeLog>]
      attr_accessor :all
    end
  end

  class Move
    attr_reader :id
    attr_reader :identifier
    attr_reader :generation_id
    attr_reader :type_id
    attr_reader :power
    attr_reader :pp
    attr_reader :accuracy
    attr_reader :priority
    attr_reader :target_id
    attr_reader :damage_class_id
    attr_reader :effect_id
    attr_reader :effect_chance
    attr_reader :contest_type_id
    attr_reader :contest_effect_id
    attr_reader :super_contest_effect_id
    def initialize(row, indexes)
      @id = row[indexes[0]].to_i
      @identifier = row[indexes[1]]
      @generation_id = row[indexes[2]].to_i
      @type_id = row[indexes[3]].to_i
      @power = row[indexes[4]].to_i
      @pp = row[indexes[5]].to_i
      @accuracy = row[indexes[6]].to_i
      @priority = row[indexes[7]].to_i
      @target_id = row[indexes[8]].to_i
      @damage_class_id = row[indexes[9]].to_i
      @effect_id = row[indexes[10]].to_i
      @effect_chance = row[indexes[11]].to_i
      @contest_type_id = row[indexes[12]].to_i
      @contest_effect_id = row[indexes[13]].to_i
      @super_contest_effect_id = row[indexes[14]].to_i
    end

    # Return an updated version of the move to the said version group
    # @param version_group_id [Integer] ID of the version group
    # @return [Move]
    def updated_to(version_group_id)
      version = MoveChangeLog.all.find do |changelog|
        changelog.id == @id && changelog.changed_in_version_group_id == version_group_id
      end
      return self unless version

      (updated_move = clone).instance_eval do
        @type_id = version.type_id if version.type_id
        @power = version.power if version.power
        @pp = version.pp if version.pp
        @accuracy = version.accuracy if version.accuracy
        @priority = version.priority if version.priority
        @target_id = version.target_id if version.target_id
        @effect_id = version.effect_id if version.effect_id
        @effect_chance = version.effect_chance if version.effect_chance
      end

      return updated_move
    end

    # @return [Integer]
    def psdk_id
      Move.psdk_move_string.index(@identifier) || @id
    end

    # @return [Integer]
    def psdk_type
      Type.all.find { |type| type.id == @type_id }.psdk_id
    end

    # @return [Integer]
    def atk_class
      return 3 if @damage_class_id == 1
      return 1 if @damage_class_id == 2

      return 2
    end

    # @return [Integer]
    def psdk_priority
      @priority + 7
    end

    class << self
      # @return [Array<Move>]
      def load(path)
        rows = CSV.read(File.join(path, 'moves.csv'))
        header = rows.shift
        indexes = [
          header.index('id') || 0,
          header.index('identifier') || 0,
          header.index('generation_id') || 0,
          header.index('type_id') || 0,
          header.index('power') || 0,
          header.index('pp') || 0,
          header.index('accuracy') || 0,
          header.index('priority') || 0,
          header.index('target_id') || 0,
          header.index('damage_class_id') || 0,
          header.index('effect_id') || 0,
          header.index('effect_chance') || 0,
          header.index('contest_type_id') || 0,
          header.index('contest_effect_id') || 0,
          header.index('super_contest_effect_id') || 0
        ]
        return @all = rows.map { |row| Move.new(row, indexes) }
      end

      # All the loaded moves
      # @return [Array<Move>]
      attr_accessor :all

      # All the psdk move string
      # @return [Array<String>]
      def psdk_move_string
        @psdk_move_string ||= GameData::Skill.all.map do |skill|
          skill.db_symbol.to_s.gsub('_', '-').gsub(',', '-').gsub('’', '')
        end
      end
    end
  end

  class Type
    attr_reader :id
    attr_reader :identifier
    attr_reader :generation_id
    attr_reader :damage_class_id
    def initialize(row, indexes)
      @id = row[indexes[0]].to_i
      @identifier = row[indexes[1]]
      @generation_id = row[indexes[2]].to_i
      @damage_class_id = row[indexes[3]].to_i
    end

    # @return [Integer]
    def psdk_id
      PSDK_TYPES[@identifier] || @id
    end

    PSDK_TYPES = {
      'normal' => GameData::Types::NORMAL,
      'fighting' => GameData::Types::FIGHTING,
      'flying' => GameData::Types::FLYING,
      'poison' => GameData::Types::POISON,
      'ground' => GameData::Types::GROUND,
      'rock' => GameData::Types::ROCK,
      'bug' => GameData::Types::BUG,
      'ghost' => GameData::Types::GHOST,
      'steel' => GameData::Types::STEEL,
      'fire' => GameData::Types::FIRE,
      'water' => GameData::Types::WATER,
      'grass' => GameData::Types::GRASS,
      'electric' => GameData::Types::ELECTRIC,
      'psychic' => GameData::Types::PSYCHIC,
      'ice' => GameData::Types::ICE,
      'dragon' => GameData::Types::DRAGON,
      'dark' => GameData::Types::DARK,
      'fairy' => GameData::Types::FAIRY,
      'unknown' => GameData::Types::T？？？
    }

    class << self
      # @return [Array<Type>]
      def load(path)
        rows = CSV.read(File.join(path, 'types.csv'))
        header = rows.shift
        indexes = [
          header.index('id') || 0,
          header.index('identifier') || 0,
          header.index('generation_id') || 0,
          header.index('damage_class_id') || 0
        ]
        return @all = rows.map { |row| Type.new(row, indexes) }
      end

      # All the loaded types
      # @return [Array<Type>]
      attr_accessor :all
    end
  end
end

# Load dependancy to properly save the output to YAML
# (Please do the ProjectToYAML.convert before PokeAPI.update(path))
ScriptLoader.load_tool('ProjectToYAML')
