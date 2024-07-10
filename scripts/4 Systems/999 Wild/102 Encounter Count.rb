module PFM
  class Wild_Battle
    # List of abilities increasing the frequency of encounter
    ENCOUNTER_FREQ_INCREASE = {}
    # List of abilities decreasing the frequency of encounter
    ENCOUNTER_FREQ_DECREASE = {}

    # Make the encounter count for each groups
    # @param only_less_than_one [Boolean] if the function should only update the group encounter count that are less or equal than 1
    def make_encounter_count(only_less_than_one = false)
      factor = encounter_count_factor
      groups_encounter_counts = @groups_encounter_steps&.map { |i| (encounter_count_from_average_steps(i) * factor).round } || []
      if only_less_than_one
        @groups_encounter_counts.map!.with_index { |c, i| c <= 0 ? groups_encounter_counts[i] : c }
      else
        @groups_encounter_counts = groups_encounter_counts
      end
    end

    # Update encounter count for each groups
    def update_encounter_count
      @groups_encounter_counts.map! { |i| i - 1 }
      make_encounter_count(true) if @groups_encounter_counts.any? { |i| i <= 0 }
    end

    # Detect if a group has encounter
    # @return [Boolean]
    def group_encounter_detected?
      indexes = detected_group_encounter_indexes
      return false if indexes.empty?

      return indexes.any? do |index|
        group = @groups[index]
        system_tag = game_state.game_player.system_tag_db_symbol
        terrain_tag = game_state.game_player.terrain_tag
        next false unless group && group.tool.nil? && group.system_tag == system_tag && group.terrain_tag == terrain_tag

        next available?
      end
    end

    # Get the index of the groups that might trigger a battle due to encounter steps depleted
    # @return [Array<Integer>]
    def detected_group_encounter_indexes
      return @groups_encounter_counts.map.with_index { |c, i| c <= 1 ? i : nil }.compact
    end

    private

    # Compute the encounter count from average steps
    def encounter_count_from_average_steps(average_steps)
      return rand(average_steps) + rand(average_steps) + 1
    end

    # Compute the encounter count factor
    # @return [Float, Integer]
    def encounter_count_factor
      ability_db_symbol = $actors[0]&.ability_db_symbol || :__undef__

      if ENCOUNTER_FREQ_INCREASE.key?(ability_db_symbol)
        return 0.5 unless ENCOUNTER_FREQ_INCREASE[ability_db_symbol]
        return 0.5 if ENCOUNTER_FREQ_INCREASE[ability_db_symbol].call
      elsif ENCOUNTER_FREQ_DECREASE.key?(ability_db_symbol)
        return 2 unless ENCOUNTER_FREQ_DECREASE[ability_db_symbol]
        return 2 if ENCOUNTER_FREQ_DECREASE[ability_db_symbol].call
      end

      return 1
    end

    class << self
      # Register an ability that increase the encounter frequency
      # @param ability_db_symbol [Symbol, Array<Symbol>] db_symbol of the ability that increase the encounter frequency
      # @param block [Proc, nil] Additional condition needed to validate the ability effect
      def register_frequency_increase_ability(ability_db_symbol, &block)
        if ability_db_symbol.is_a?(Array)
          ability_db_symbol.each do |db_symbol|
            ENCOUNTER_FREQ_INCREASE[db_symbol] = block
          end
        else
          ENCOUNTER_FREQ_INCREASE[ability_db_symbol] = block
        end
      end

      # Register an ability that decrease the encounter frequency
      # @param ability_db_symbol [Symbol, Array<Symbol>] db_symbol of the ability that decrease the encounter frequency
      # @param block [Proc, nil] Additional condition needed to validate the ability effect
      def register_frequency_decrease_ability(ability_db_symbol, &block)
        if ability_db_symbol.is_a?(Array)
          ability_db_symbol.each do |db_symbol|
            ENCOUNTER_FREQ_DECREASE[db_symbol] = block
          end
        else
          ENCOUNTER_FREQ_DECREASE[ability_db_symbol] = block
        end
      end
    end
  end
end

Graphics.on_start do
  PFM::Wild_Battle.register_frequency_increase_ability(%i[no_guard illuminate arena_trap])
  PFM::Wild_Battle.register_frequency_decrease_ability(%i[white_smoke quick_feet stench])
  PFM::Wild_Battle.register_frequency_decrease_ability(:snow_cloak) { $env.hail? }
  PFM::Wild_Battle.register_frequency_decrease_ability(:sand_veil) { $env.sandstorm? }
end
