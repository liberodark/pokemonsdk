module Studio
  # Data class describing a wild Group
  class Group
    # ID of the group
    # @return [Integer]
    attr_reader :id

    # db_symbol of the group
    # @return [Symbol]
    attr_reader :db_symbol

    # System tag in which the wild creature should appear
    # @return [Symbol]
    attr_reader :system_tag

    # Terrain tag in which the wild creature should appear
    # @return [Integer]
    attr_reader :terrain_tag

    # Tool used to trigger that group (:old_rod, :good_rod, :super_rod, :rock_smash, :head_butt)
    # @return [Symbol, nil]
    attr_reader :tool

    # If the wild battle should be a double battle
    # @return [Boolean]
    attr_reader :is_double_battle

    # If the wild battle should be a horde battle
    # @return [Boolean]
    attr_reader :is_horde_battle

    # All the custom condition for the group to be active
    # @return [Array<CustomCondition>]
    attr_reader :custom_conditions

    # All the wild encounters
    # @return [Array<Encounter>]
    attr_reader :encounters

    # Average number of steps for the group to have a creature spawn
    # @return [Integer]
    attr_reader :steps_average

    # Data class describing a custom group condition
    class CustomCondition
      # Type of the custom condition (:enabled_switch or :map_id)
      # @return [Symbol]
      attr_reader :type

      # Value of the condition
      # @return [Integer]
      attr_reader :value

      # Relation of the condition (:AND, :OR)
      # @return [Symbol]
      attr_reader :relation_with_previous_condition

      # Evaluate the condition in a reduce context
      # @param previous [Boolean] result of the previous condition
      # @return [Boolean]
      def reduce_evaluate(previous)
        return false if @relation_with_previous_condition == :AND && !previous
        return true if @relation_with_previous_condition == :OR && previous

        return evaluate
      end

      # Evaluate the condition
      def evaluate
        case @type
        when :enabled_switch
          return PFM.game_state.game_switches[@value]
        when :map_id
          return PFM.game_state.game_map.map_id == @value
        else
          return false
        end
      end
    end

    # Data class describing an Encounter for a wild group
    class Encounter
      # db_symbol of the creature that should be encountered
      # @return [Symbol]
      attr_reader :specie

      # Form of the creature that should be encountered
      # @return [Integer]
      attr_reader :form

      # Shiny attribute setup for the creature
      # @return [ShinySetup]
      attr_reader :shiny_setup

      # Level setup of the creature that should be encountered
      # @return [LevelSetup]
      attr_reader :level_setup

      # Encounter rate of the creature in its group
      # @return [Integer]
      attr_reader :encounter_rate

      # Additional info for the creature (to generate it)
      # @return [Hash]
      attr_reader :extra

      # Convert the encounter to an actual creature
      # @param level [Integer] level generated through outside factor (ability / other)
      # @return [PFM::Pokemon]
      def to_creature(level = nil)
        level ||= rand(level_setup.range)
        return PFM::Pokemon.new(specie, level, shiny_setup.shiny, shiny_setup.not_shiny, generic_form_generation, extra)
      end

      # Generate generic form generation between 0 and 29 if form == -1 and the Pokemon has not a FORM_GENERATION
      def generic_form_generation
        return form if form != -1 || PFM::Pokemon::FORM_GENERATION[specie]

        forms = data_creature(specie).forms
        forms.reject! { |creature_form| creature_form.form >= 30 }
        return forms.sample&.form || form
      end

      # Data class helping to know the shiny setup of a creature
      class ShinySetup
        # Create a new shiny setup
        # @param hash [Hash] shiny setup info
        def initialize(hash)
          @kind = hash['kind'].to_sym
          @rate = hash['rate'].to_f
        end

        # Get the shiny attribute of the creature
        # @param rate [Float] current rate to guess the creature shiny rate
        # @return [Boolean]
        def shiny(rate = rand)
          return false if @kind == :automatic

          return @rate > rate
        end

        # Get the forbid shiny attribute
        # @return [Boolean]
        def not_shiny
          return false if @kind == :automatic

          return @rate == 0
        end
      end

      # Data class helping to know the level setup of a creature while picking its level from group
      class LevelSetup
        # Get the level range (to give to a rand function) to get the final level of the creature
        # @return [Range]
        attr_reader :range

        # Create a new level setup
        # @param hash [Hash]
        def initialize(hash)
          @kind = hash['kind'].to_sym
          min_level = @kind == :fixed ? hash['level'].to_i : hash['level']['minimumLevel'].to_i
          max_level = @kind == :fixed ? hash['level'].to_i : hash['level']['maximumLevel'].to_i
          @range = min_level..max_level
        end

        # Tell if that level setup makes the encounter rejected by repel
        # @param actor_level [Integer]
        # @return [Boolean]
        def repel_rejected(actor_level)
          return @range.end < actor_level
        end

        # Tell if that level setup makes the encounter being selected because actor is weaker
        # @param actor_level [Integer]
        # @return [Boolean]
        def strong_selected(actor_level)
          return @range.end + 5 >= actor_level
        end
      end
    end
  end
end
