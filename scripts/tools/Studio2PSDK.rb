# frozen_string_literal: true

# This script allow to convert the project to a PSDK Editor Project
#
# To get access to this script write :
#   ScriptLoader.load_tool('Studio2PSDK')
#
# To execute this script write :
#   Studio2PSDK.try_convert
module Studio2PSDK
  # Root folder of the PSDK Editor data
  ROOT = 'Data/Studio'
  # Instance variable dictionary
  INSTANCE_VARIABLE = Hash.new { |hash, key| hash[key] = :"@#{key.gsub(/[A-Z]/) { |v| "_#{v.downcase}" }}" }
  # List of string properties
  STRING_PROPERTIES = %w[icon spriteFilename image]
  # Mapping of symbol to other symbols
  SYMBOL_MAPPING = {
    HP: :hp,
    ATK: :atk,
    DFE: :dfe,
    SPD: :spd,
    ATS: :ats,
    DFS: :dfs,
    EVA: :eva,
    ACC: :acc,
    ATK_STAGE: :atk,
    DFE_STAGE: :dfe,
    SPD_STAGE: :spd,
    ATS_STAGE: :ats,
    DFS_STAGE: :dfs,
    EVA_STAGE: :eva,
    ACC_STAGE: :acc,
    RegularGround: :regular_ground,
    Grass: :grass,
    TallGrass: :tall_grass,
    Cave: :cave,
    Mountain: :mountain,
    Ocean: :sea,
    Sand: :sand,
    Pond: :pond,
    UnderWater: :under_water,
    Snow: :snow,
    Ice: :ice,
    OldRod: :old_rod,
    GoodRod: :good_rod,
    SuperRod: :super_rod,
    RockSmash: :rock_smash,
    HeadButt: :headbutt
  }

  module_function

  # Function that attempts to convert (if it's actually needed)
  def try_convert
    return if no_need_to_convert?

    unless File.exist?(ROOT)
      ScriptLoader.load_tool('PSDKEditor')
      PSDKEditor.convert
    end
    convert
  end

  # Function that converts the studio data to SDK data
  def convert
    @data ||= {}

    convert_all_entities((directories.map { |dirname| dirname.split('/').last }).reject { |dirname| dirname == 'maps' })

    puts 'saving'
    File.binwrite(File.join(ROOT, 'psdk.dat'), Marshal.dump(@data))
    puts 'done'
  end

  def cleanup
    @data = nil
    @mtimes = nil
    INSTANCE_VARIABLE.clear
    GC.start
  end

  # Function that checks if that's not needed to convert
  def no_need_to_convert?
    binary_filename = File.join(ROOT, 'psdk.dat')
    return File.exist?(binary_filename)
  end

  # Function that gives all the directories from studio
  # @return [Array<String>]
  def directories
    return Dir[File.join(ROOT, '**')].select { |dirname| File.directory?(dirname) }.sort
  end

  # Function that converts all the entities
  # @param folder_names [Array<String>] name of the folders containing json files
  def convert_all_entities(folder_names)
    folder_names.each do |folder|
      folder_sym = folder == 'pokemon' ? :creatures : folder.to_sym
      puts "converting #{folder_sym}"
      entities = Dir[File.join(ROOT, folder, '*.json')].map { |filename| json_to_psdk_studio_object(JSON.parse(File.read(filename))) }
      @data[folder_sym] = entities.map { |entity| [entity.db_symbol, entity] }.to_h
      @data[folder_sym][:__undef__] = make_undef_entity(folder_sym, (entities.find { |entity| entity.id == 0 } || entities.first).dup)
      @data[:"#{folder_sym}__id"] = @data[folder_sym].values.sort_by(&:id)
    end
    # Remove the first creature/item/move so iterating through them will not cause any issue
    @data[:creatures__id].delete_if { |c| c.id == 0 || c.db_symbol == :__undef__ }
    @data[:items__id].delete_if { |c| c.id == 0 || c.db_symbol == :__undef__ }
    @data[:moves__id].delete_if { |c| c.id == 0 || c.db_symbol == :__undef__ }
  end

  # Function that builds the undef entity
  # @param folder_sym [Symbol]
  # @param undef_entity [Object]
  def make_undef_entity(folder_sym, undef_entity)
    undef_entity.instance_variable_set(:@db_symbol, :__undef__)
    undef_entity.instance_variable_set(:@id, 0)
    case folder_sym
    when :types
      undef_entity.instance_variable_set(:@text_id, 0)
      undef_entity.instance_variable_set(:@damage_to, [])
    when :quests, :worldmaps, :abilities, :groups, :trainers
      undef_entity.instance_variable_set(:@id, -1)
    when :zones
      undef_entity.instance_variable_set(:@id, -1)
      undef_entity.instance_variable_set(:@maps, [])
      undef_entity.instance_variable_set(:@worldmaps, [])
      undef_entity.instance_variable_set(:@wild_groups, [])
      undef_entity.instance_variable_set(:@panel_id, 0)
    when :items
      undef_entity.instance_variable_set(:@icon, 'return')
      undef_entity.instance_variable_set(:@price, 0)
      undef_entity.instance_variable_set(:@socket, 0)
      undef_entity.instance_variable_set(:@is_battle_usable, false)
      undef_entity.instance_variable_set(:@is_map_usable, false)
      undef_entity.instance_variable_set(:@is_limited, true)
      undef_entity.instance_variable_set(:@is_holdable, false)
      undef_entity.instance_variable_set(:@fling_power, 0)
    when :dex
      undef_entity.instance_variable_set(:@creatures, [])
      undef_entity.instance_variable_set(:@id, -1)
    when :maplinks
      undef_entity.instance_variable_set(:@id, -1)
      undef_entity.instance_variable_set(:@map_id, -1)
      undef_entity.instance_variable_set(:@north_maps, [])
      undef_entity.instance_variable_set(:@east_maps, [])
      undef_entity.instance_variable_set(:@south_maps, [])
      undef_entity.instance_variable_set(:@west_maps, [])
    end

    return undef_entity
  end

  # Function that converts a json to a Ruby object from Studio module
  def json_to_psdk_studio_object(json_object)
    case json_object
    when Array
      return json_object.map { |object| json_to_psdk_studio_object(object) }
    when Hash
      if json_object['klass']
        klass = Studio.const_get(json_object['klass'])
        obj = klass.allocate
        json_object.each do |key, value|
          next if key == 'klass'

          ivar_value = STRING_PROPERTIES.include?(key) ? value.to_s : json_to_psdk_studio_object(value)
          obj.instance_variable_set(INSTANCE_VARIABLE[key], ivar_value)
        end
        return post_process_psdk_studio_object(obj)
      else
        return psdk_studio_object_from_hash(json_object)
      end
    when String
      symbol = json_object.to_sym
      return SYMBOL_MAPPING[symbol] || symbol
    end
    return json_object
  end

  # Function that post process a psdk studio object
  def post_process_psdk_studio_object(obj)
    if obj.is_a?(Studio::Specie)
      obj.forms.each do |form|
        form.instance_variable_set(:@db_symbol, obj.db_symbol)
        form.instance_variable_set(:@id, obj.id)
      end
    end
    if obj.is_a?(Studio::StatusHealItem) || obj.is_a?(Studio::StatusConstantHealItem) || obj.is_a?(Studio::StatusRateHealItem)
      obj.status_list.map! { |status| Studio::Move::MoveStatus::STATUS_TRANSLATION[status.to_s] }
    end
    if obj.is_a?(Studio::Move)
      obj.instance_variable_set(:@effect_chance, 100) unless obj.effect_chance
    end
    if obj.is_a?(Studio::Group)
      obj.instance_variable_set(:@system_tag, obj.system_tag.downcase) if obj.system_tag.match?('Custom_')
      obj.instance_variable_set(:@tool, obj.system_tag) if obj.system_tag == :headbutt
    end
    return obj
  end

  # Function that attemps to conver the hash to an existing Ruby object from Studio module
  def psdk_studio_object_from_hash(hash)
    obj = Studio::Group::CustomCondition.try_create(hash) ||
          Studio::Group::Encounter.try_create(hash) ||
          Color.try_create(hash) ||
          Studio::Move::BattleStageMod.try_create(hash) ||
          Studio::Move::MoveStatus.try_create(hash) ||
          Studio::CreatureForm.try_create(hash) ||
          Studio::Trainer::Resources.try_create(hash) ||
          Studio::Quest::Objective.try_create(hash) ||
          Studio::Quest::Earning.try_create(hash) ||
          Studio::Type::DamageTo.try_create(hash) ||
          Studio::Zone::MapCoordinate.try_create(hash) ||
          Studio::CSVAccess.try_create(hash) ||
          Studio::MapLink::Link.try_create(hash) ||
          Studio::Dex::CreatureInfo.try_create(hash)

    return obj if obj

    return hash.map { |(key, value)| [key.to_sym, json_to_psdk_studio_object(value)] }.to_h
  end
end

class Color
  class << self
    # Attempt to create a new color
    # @param hash [Hash]
    def try_create(hash)
      return unless (red = hash['red']).is_a?(Integer)
      return unless (green = hash['green']).is_a?(Integer)
      return unless (blue = hash['blue']).is_a?(Integer)
      return unless (alpha = hash['alpha']).is_a?(Integer)

      return new(red, green, blue, alpha)
    end
  end
end

module Studio
  # Compatibility layer so const_get gets Specie as Creature
  Specie = Creature
  TrainerBattleSetup = Trainer
  class Group
    class CustomCondition
      CONDITION_MAP = { 'enabledSwitch' => :enabled_switch, 'mapId' => :map_id }
      RELATION_TYPES = %w[AND OR]

      class << self
        # Attempt to create a new custom condition
        # @param hash [Hash]
        def try_create(hash)
          return unless (type = CONDITION_MAP[hash['type']])
          return unless (value = hash['value']).is_a?(Integer)
          return unless RELATION_TYPES.include?(hash['relationWithPreviousCondition'])

          obj = allocate
          obj.instance_variable_set(:@type, type)
          obj.instance_variable_set(:@value, value)
          obj.instance_variable_set(:@relation_with_previous_condition, hash['relationWithPreviousCondition'].to_sym)
          return obj
        end
      end
    end

    class Encounter
      class << self
        # Attempt to create a new encounter
        # @param hash [Hash]
        def try_create(hash)
          return unless (specie = hash['specie'])
          return unless (form = hash['form']).is_a?(Integer)
          return unless (shiny_setup = hash['shinySetup']).is_a?(Hash)
          return unless (level_setup = hash['levelSetup']).is_a?(Hash)
          return unless (encounter_rate = hash['randomEncounterChance']).is_a?(Integer)
          return unless (extra = hash['expandPokemonSetup']).is_a?(Array)

          obj = allocate
          obj.instance_variable_set(:@specie, specie.to_sym)
          obj.instance_variable_set(:@form, form)
          obj.instance_variable_set(:@encounter_rate, encounter_rate)
          obj.instance_variable_set(:@shiny_setup, ShinySetup.new(shiny_setup))
          obj.instance_variable_set(:@level_setup, LevelSetup.new(level_setup))
          obj.instance_variable_set(:@extra, build_extra_hash(extra))
          return obj
        end

        def build_extra_hash(extra)
          return extra.map do |entry|
            case entry['type']
            when 'givenName'
              next [:given_name, entry['value'].to_s]
            when 'caughtWith'
              next [:captured_with, entry['value'].to_sym]
            when 'gender'
              next [:gender, entry['value']]
            when 'nature'
              next [:nature, entry['value'].to_sym]
            when 'ivs'
              next [:stats, [
                entry['value']['hp'].to_i,
                entry['value']['atk'].to_i,
                entry['value']['dfe'].to_i,
                entry['value']['spd'].to_i,
                entry['value']['ats'].to_i,
                entry['value']['dfs'].to_i
              ]]
            when 'evs'
              next [:bonus, [
                entry['value']['hp'].to_i,
                entry['value']['atk'].to_i,
                entry['value']['dfe'].to_i,
                entry['value']['spd'].to_i,
                entry['value']['ats'].to_i,
                entry['value']['dfs'].to_i
              ]]
            when 'itemHeld'
              next [:item, entry['value'].to_sym]
            when 'ability'
              next [:ability, entry['value'].to_sym]
            when 'rareness'
              next [:rareness, entry['value'].to_i]
            when 'loyalty'
              next [:loyalty, entry['value'].to_i]
            when 'moves'
              next [:moves, entry['value'].map(&:to_sym)]
            when 'originalTrainerName'
              next [:trainer_name, entry['value'].to_s]
            when 'originalTrainerId'
              next [:trainer_id, entry['value'].to_i]
            end
          end.to_h
        end
      end
    end
  end

  class Move
    class BattleStageMod
      STAT_TRANSLATION = {
        'ATK_STAGE' => :atk,
        'DFE_STAGE' => :dfe,
        'ATS_STAGE' => :ats,
        'DFS_STAGE' => :dfs,
        'SPD_STAGE' => :spd,
        'EVA_STAGE' => :eva,
        'ACC_STAGE' => :acc
      }

      class << self
        # Attempt to create a new battle stage mod
        # @param hash [Hash]
        def try_create(hash)
          return unless (stat = hash['battleStage'])
          return unless (count = hash['modificator']).is_a?(Integer)

          obj = allocate
          obj.instance_variable_set(:@stat, STAT_TRANSLATION[stat] || :atk)
          obj.instance_variable_set(:@count, count)
          return obj
        end
      end
    end

    class MoveStatus
      STATUS_TRANSLATION = {
        'POISONED' => :poison,
        'PARALYZED' => :paralysis,
        'BURN' => :burn,
        'ASLEEP' => :sleep,
        'FROZEN' => :freeze,
        'CONFUSED' => :confusion,
        'TOXIC' => :toxic,
        'FLINCH' => :flinch,
        'DEATH' => :death,
        'KO' => :ko
      }

      class << self
        # Attempt to create a new move status
        # @param hash [Hash]
        def try_create(hash)
          return unless (status = hash['status'])
          return unless (luck_rate = hash['luckRate']).is_a?(Integer)

          obj = allocate
          obj.instance_variable_set(:@status, STATUS_TRANSLATION[status] || :confusion)
          obj.instance_variable_set(:@luck_rate, luck_rate)
          return obj
        end
      end
    end
  end

  class CreatureForm
    class << self
      # Attempt to create a new Creature Form
      # @param hash [Hash]
      def try_create(hash)
        return unless (form = hash['form']).is_a?(Integer)
        return unless (height = hash['height'])
        return unless (weight = hash['weight'])
        return unless (type1 = hash['type1']).is_a?(String)
        return unless (type2 = hash['type2']).is_a?(String)
        return unless (base_hp = hash['baseHp']).is_a?(Integer)
        return unless (base_atk = hash['baseAtk']).is_a?(Integer)
        return unless (base_dfe = hash['baseDfe']).is_a?(Integer)
        return unless (base_spd = hash['baseSpd']).is_a?(Integer)
        return unless (base_ats = hash['baseAts']).is_a?(Integer)
        return unless (base_dfs = hash['baseDfs']).is_a?(Integer)
        return unless (ev_hp = hash['evHp']).is_a?(Integer)
        return unless (ev_atk = hash['evAtk']).is_a?(Integer)
        return unless (ev_dfe = hash['evDfe']).is_a?(Integer)
        return unless (ev_spd = hash['evSpd']).is_a?(Integer)
        return unless (ev_ats = hash['evAts']).is_a?(Integer)
        return unless (ev_dfs = hash['evDfs']).is_a?(Integer)
        return unless (evolutions = hash['evolutions']).is_a?(Array)
        return unless (experience_type = hash['experienceType']).is_a?(Integer)
        return unless (base_experience = hash['baseExperience']).is_a?(Integer)
        return unless (base_loyalty = hash['baseLoyalty']).is_a?(Integer)
        return unless (catch_rate = hash['catchRate']).is_a?(Integer)
        return unless (female_rate = hash['femaleRate'])
        return unless (breed_groups = hash['breedGroups']).is_a?(Array)
        return unless (hatch_steps = hash['hatchSteps']).is_a?(Integer)
        return unless (baby_db_symbol = hash['babyDbSymbol']).is_a?(String)
        return unless (baby_form = hash['babyForm']).is_a?(Integer)
        return unless (item_held = hash['itemHeld']).is_a?(Array)
        return unless (abilities = hash['abilities']).is_a?(Array)
        return unless (front_offset_y = hash['frontOffsetY']).is_a?(Integer)
        return unless (move_set = hash['moveSet']).is_a?(Array)
        return unless (resources = hash['resources']).is_a?(Hash)

        obj = allocate
        obj.instance_variable_set(:@form, form)
        obj.instance_variable_set(:@height, height)
        obj.instance_variable_set(:@weight, weight)
        obj.instance_variable_set(:@type1, type1.to_sym)
        obj.instance_variable_set(:@type2, type2.to_sym)
        obj.instance_variable_set(:@base_hp, base_hp)
        obj.instance_variable_set(:@base_atk, base_atk)
        obj.instance_variable_set(:@base_dfe, base_dfe)
        obj.instance_variable_set(:@base_spd, base_spd)
        obj.instance_variable_set(:@base_ats, base_ats)
        obj.instance_variable_set(:@base_dfs, base_dfs)
        obj.instance_variable_set(:@ev_hp, ev_hp)
        obj.instance_variable_set(:@ev_atk, ev_atk)
        obj.instance_variable_set(:@ev_dfe, ev_dfe)
        obj.instance_variable_set(:@ev_spd, ev_spd)
        obj.instance_variable_set(:@ev_ats, ev_ats)
        obj.instance_variable_set(:@ev_dfs, ev_dfs)
        obj.instance_variable_set(:@evolutions, evolutions.map { |evolution| Studio::CreatureForm::Evolution.new(evolution) })
        obj.instance_variable_set(:@experience_type, experience_type)
        obj.instance_variable_set(:@base_experience, base_experience)
        obj.instance_variable_set(:@base_loyalty, base_loyalty)
        obj.instance_variable_set(:@catch_rate, catch_rate)
        obj.instance_variable_set(:@female_rate, female_rate)
        obj.instance_variable_set(:@breed_groups, breed_groups)
        obj.instance_variable_set(:@hatch_steps, hatch_steps)
        obj.instance_variable_set(:@baby_db_symbol, baby_db_symbol.to_sym)
        obj.instance_variable_set(:@baby_form, baby_form)
        obj.instance_variable_set(:@item_held, item_held.map { |item| Studio::CreatureForm::ItemHeld.new(item) })
        obj.instance_variable_set(:@abilities, abilities.map(&:to_sym))
        obj.instance_variable_set(:@front_offset_y, front_offset_y)
        obj.instance_variable_set(:@move_set, move_set.map { |move| Studio2PSDK.json_to_psdk_studio_object(move) })
        obj.instance_variable_set(:@resources, Studio::CreatureForm::Resources.new(resources))
        return obj
      end
    end

    class Evolution
      def initialize(hash)
        @db_symbol = (hash['dbSymbol'] || '__undef__').to_sym
        @form = hash['form']
        @conditions = Studio2PSDK.json_to_psdk_studio_object(hash['conditions'])
      end
    end

    class ItemHeld
      def initialize(hash)
        @db_symbol = hash['dbSymbol'].to_sym
        @chance = hash['chance']
      end
    end

    class Resources
      def initialize(hash)
        @icon = hash['icon']
        @icon_f = hash['iconF']
        @icon_shiny = hash['iconShiny']
        @icon_shiny_f = hash['iconShinyF']
        @front = hash['front']
        @front_f = hash['frontF']
        @front_shiny = hash['frontShiny']
        @front_shiny_f = hash['frontShinyF']
        @back = hash['back']
        @back_f = hash['backF']
        @back_shiny = hash['backShiny']
        @back_shiny_f = hash['backShinyF']
        @footprint = hash['footprint']
        @character = hash['character']
        @character_f = hash['characterF']
        @character_shiny = hash['characterShiny']
        @character_shiny_f = hash['characterShinyF']
        @cry = hash['cry']
        @has_female = hash['hasFemale']
      end
    end
  end

  class Trainer
    class Resources
      class << self
        def try_create(hash)
          return unless (sprite = hash['sprite']).is_a?(String)
          return unless (artwork_full = hash['artworkFull']).is_a?(String)
          return unless (artwork_small = hash['artworkSmall']).is_a?(String)
          return unless (character = hash['character']).is_a?(String)
          return unless (encounter_bgm = hash['musics']['encounter']).is_a?(String)
          return unless (victory_bgm = hash['musics']['victory']).is_a?(String)
          return unless (defeat_bgm = hash['musics']['defeat']).is_a?(String)
          return unless (battle_bgm = hash['musics']['bgm']).is_a?(String)

          obj = allocate
          obj.instance_variable_set(:@sprite, sprite)
          obj.instance_variable_set(:@artwork_full, artwork_full)
          obj.instance_variable_set(:@artwork_small, artwork_small)
          obj.instance_variable_set(:@character, character)
          obj.instance_variable_set(:@encounter_bgm, encounter_bgm)
          obj.instance_variable_set(:@victory_bgm, victory_bgm)
          obj.instance_variable_set(:@defeat_bgm, defeat_bgm)
          obj.instance_variable_set(:@battle_bgm, battle_bgm)
          return obj
        end
      end
    end
  end

  class Quest
    class Objective
      class << self
        # Attempt to create a new Objective
        # @param hash [Hash]
        def try_create(hash)
          return unless (objective_method_name = hash['objectiveMethodName']).is_a?(String)
          return unless (objective_method_args = hash['objectiveMethodArgs']).is_a?(Array)
          return unless (text_format_method_name = hash['textFormatMethodName']).is_a?(String)
          return unless (hidden_by_default = hash['hiddenByDefault']).is_a?(Boolean)

          obj = allocate
          obj.instance_variable_set(:@objective_method_name, objective_method_name.to_sym)
          if objective_method_name.to_sym == :objective_catch_pokemon
            obj.instance_variable_set(:@objective_method_args, generate_pokemon_conditions_hash(objective_method_args))
          else
            obj.instance_variable_set(:@objective_method_args, Studio2PSDK.json_to_psdk_studio_object(objective_method_args))
          end
          obj.instance_variable_set(:@text_format_method_name, text_format_method_name.to_sym)
          obj.instance_variable_set(:@hidden_by_default, hidden_by_default)
          return obj
        end

        # Method that generates the pokemon hash
        # @param conditions [Array<Hash>] Hash containing all the Studio conditions
        # @return [Hash]
        def generate_pokemon_conditions_hash(conditions)
          cond = conditions.first
          return unless cond.is_a?(Array)

          h = {}
          cond.each do |c|
            type = c['type']
            value = c['value']
            h.store(:id, value.to_sym) if type == 'pokemon'
            if type == 'type'
              h.key?(:type) ? h.store(:type2, value.to_sym) : h.store(:type, value.to_sym)
            end
            h.store(:nature, value.to_sym) if type == 'nature'
            h.store(:min_level, value) if type == 'minLevel'
            h.store(:max_level, value) if type == 'maxLevel'
            h.store(:level, value) if type == 'level'
          end
          return [h, conditions.last]
        end
      end
    end

    class Earning
      class << self
        # Attempt to create a new Earning
        # @param hash [Hash]
        def try_create(hash)
          return unless (earning_method_name = hash['earningMethodName']).is_a?(String)
          return unless (earning_args = hash['earningArgs']).is_a?(Array)
          return unless (text_format_method_name = hash['textFormatMethodName']).is_a?(String)

          obj = allocate
          obj.instance_variable_set(:@earning_method_name, earning_method_name.to_sym)
          obj.instance_variable_set(:@earning_args, Studio2PSDK.json_to_psdk_studio_object(earning_args))
          obj.instance_variable_set(:@text_format_method_name, text_format_method_name.to_sym)
          return obj
        end
      end
    end
  end

  class Type
    class DamageTo
      class << self
        # Attempt to create a new DamageTo
        # @param hash [Hash]
        def try_create(hash)
          return unless (defensive_type = hash['defensiveType']).is_a?(String)
          return unless (factor = hash['factor']).is_a?(Numeric)

          obj = allocate
          obj.instance_variable_set(:@defensive_type, defensive_type.to_sym)
          obj.instance_variable_set(:@factor, factor)
          return obj
        end
      end
    end
  end

  class Zone
    class MapCoordinate
      class << self
        # Attempt to create a new MapCoordinate
        # @param hash [Hash]
        def try_create(hash)
          return unless (x = hash['x']).is_a?(Integer) || hash.key?('x')
          return unless (y = hash['y']).is_a?(Integer) || hash.key?('y')

          obj = allocate
          obj.instance_variable_set(:@x, x)
          obj.instance_variable_set(:@y, y)
          return obj
        end
      end
    end
  end

  class CSVAccess
    class << self
      # Attempt to create a new MapCoordinate
      # @param hash [Hash]
      def try_create(hash)
        return unless (file_id = hash['csvFileId']).is_a?(Integer)
        return unless (text_index = hash['csvTextIndex']).is_a?(Integer)

        obj = allocate
        obj.instance_variable_set(:@file_id, file_id)
        obj.instance_variable_set(:@text_index, text_index)
        return obj
      end
    end
  end

  class Dex
    class CreatureInfo
      class << self
        # Attempt to create a new move status
        # @param hash [Hash]
        def try_create(hash)
          return if hash.size != 2
          return unless (db_symbol = hash['dbSymbol']).is_a?(String)
          return unless (form = hash['form']).is_a?(Integer)

          obj = allocate
          obj.instance_variable_set(:@db_symbol, db_symbol.to_sym)
          obj.instance_variable_set(:@form, form)
          return obj
        end
      end
    end
  end

  class MapLink
    class Link
      class << self
        # Attempt to create a new link
        # @param hash [Hash]
        def try_create(hash)
          return unless (map_id = hash['mapId']).is_a?(Integer)
          return unless (offset = hash['offset']).is_a?(Integer)

          obj = allocate
          obj.instance_variable_set(:@map_id, map_id)
          obj.instance_variable_set(:@offset, offset)
          return obj
        end
      end
    end
  end
end
