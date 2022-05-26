module PFM
  # The Pokedex informations
  #
  # The main Pokedex object is stored in $pokedex or PFM.game_state.pokedex
  #
  # All Creature are usually marked as seen or captured in the correct scripts using $pokedex.mark_seen(id)
  # or $pokedex.mark_captured(id).
  #
  # When the Pokedex is disabled, no Creature can be marked as seen (unless they're added to the party).
  # All caught Creature are marked as captured so if for scenaristic reason you need the trainer to catch Creature
  # before having the Pokedex. Don't forget to call $pokedex.unmark_captured(id) (as well $pokedex.unmark_seen(id))
  # @author Nuri Yuri
  class Pokedex
    # Get the game state responsive of the whole game state
    # @return [PFM::GameState]
    attr_accessor :game_state

    # Get the current dex variant
    # @return [Symbol]
    attr_reader :variant

    # Get the list of seen variants
    # @return [Array<Symbol>]
    attr_reader :seen_variants

    # Create a new Pokedex object
    # @param game_state [PFM::GameState] game state storing this instance
    def initialize(game_state = PFM.game_state)
      @seen = 0
      @captured = 0
      @has_seen_and_forms = Hash.new(0)
      @has_captured = []
      @nb_fought = Hash.new(0)
      @nb_captured = Hash.new(0)
      @game_state = game_state
      @variant = :regional
      @seen_variants = [@variant]
    end

    # Convert the dex to .26 format
    def convert_to_dot26
      @variant ||= :regional
      @seen_variants ||= [@variant]
      if @has_seen_and_forms.is_a?(Hash)
        @has_seen_and_forms.delete_if { |_, v| v.nil? } if @has_seen_and_forms.value?(nil)
        @nb_fought.delete_if { |_, v| v.nil? } if @nb_fought.value?(nil)
        @nb_captured.delete_if { |_, v| v.nil? } if @nb_captured.value?(nil)
        return
      end

      all_db_symbols = [
        @has_seen_and_forms.size,
        @has_captured.size,
        @nb_fought.size,
        @nb_captured.size
      ].max.times.map { |i| data_creature(i).db_symbol }

      has_seen_and_forms = @has_seen_and_forms.map.with_index { |v, i| !v || v == 0 ? nil : [all_db_symbols[i], v] }.compact.to_h
      has_captured = @has_captured.map.with_index { |v, i| v ? all_db_symbols[i] : nil }.compact
      nb_fought = @nb_fought.map.with_index { |v, i| !v || v == 0 ? nil : [all_db_symbols[i], v] }.compact.to_h
      nb_captured = @nb_captured.map.with_index { |v, i| !v || v == 0 ? nil : [all_db_symbols[i], v] }.compact.to_h

      @has_seen_and_forms = Hash.new(0)
      @has_seen_and_forms.merge!(has_seen_and_forms)
      @has_captured = has_captured
      @nb_fought = Hash.new(0)
      @nb_fought.merge!(nb_fought)
      @nb_captured = Hash.new(0)
      @nb_captured.merge!(nb_captured)
    end

    # Enable the Pokedex
    def enable
      @game_state.game_switches[Yuki::Sw::Pokedex] = true
    end

    # Test if the Pokedex is enabled
    # @return [Boolean]
    def enabled?
      @game_state.game_switches[Yuki::Sw::Pokedex]
    end

    # Disable the Pokedex
    def disable
      @game_state.game_switches[Yuki::Sw::Pokedex] = false
    end

    # Set the national flag of the Pokedex
    # @param mode [Boolean] the flag
    def national=(mode)
      @game_state.game_switches[Yuki::Sw::Pokedex_Nat] = (mode == true)
      if mode
        self.variant = :national
      else
        @seen_variants.delete(:national)
        self.variant = @seen_variants.first || :regional
      end
    end
    alias set_national national=

    # Set the variant the Dex is currently showing
    # @param variant [Symbol]
    def variant=(variant)
      return unless each_data_dex.any? { |dex| dex.db_symbol == variant }

      @variant = variant
      @seen_variants << variant unless @seen_variants.include?(variant)
    end

    # Is the Pokedex showing national Creature
    # @return [Boolean]
    def national?
      return @game_state.game_switches[Yuki::Sw::Pokedex_Nat]
    end

    # Return the number of Creature seen
    # @return [Integer]
    def creature_seen
      return @seen
    end
    alias pokemon_seen creature_seen

    # Return the number of caught Creature
    # @return [Integer]
    def creature_caught
      return @captured
    end
    alias pokemon_captured creature_caught

    # Return the number of Creature captured by specie
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @return [Integer]
    def creature_caught_count(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return @nb_captured[db_symbol]
    end

    # Change the number of Creature captured by specie
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @param number [Integer] the new number
    def set_creature_caught_count(db_symbol, number)
      return unless enabled?

      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      @nb_captured[db_symbol] = number.to_i
    end

    # Increase the number of Creature captured by specie
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    def increase_creature_caught_count(db_symbol)
      return unless enabled?

      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      @nb_captured[db_symbol] += 1
    end
    alias pokemon_captured_inc increase_creature_caught_count

    # Return the number of Creature fought by specie
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @return [Integer]
    def creature_fought(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return @nb_fought[db_symbol]
    end

    # Change the number of Creature fought by specie
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @param number [Integer] the number of Creature fought in the specified specie
    def set_creature_fought(db_symbol, number)
      return unless enabled?

      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      @nb_fought[db_symbol] = number.to_i
    end

    # Increase the number of Creature fought by specie
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    def increase_creature_fought(db_symbol)
      return unless enabled?

      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      @nb_fought[db_symbol] += 1
    end
    alias pokemon_fought_inc increase_creature_fought

    # Mark a creature as seen
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @param form [Integer] the specific form of the Creature
    # @param forced [Boolean] if the Creature is marked seen even if the Pokedex is disabled
    #                         (Giving Creature before givin the Pokedex).
    def mark_seen(db_symbol, form = 0, forced: false)
      return unless enabled? || forced

      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__
      return unless creature_unlocked?(db_symbol) || forced

      @seen += 1 if @has_seen_and_forms[db_symbol] == 0
      @has_seen_and_forms[db_symbol] |= (1 << form)
      @game_state.game_variables[Yuki::Var::Pokedex_Seen] = @seen
    end

    # Unmark a creature as seen
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @param form [Integer, false] if false, all form will be unseen, otherwise the specific form will be unseen
    def unmark_seen(db_symbol, form: false)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      if form
        @has_seen_and_forms[db_symbol] &= ~(1 << form)
      else
        @has_seen_and_forms.delete(db_symbol)
      end
      @seen -= 1 if !form || @has_seen_and_forms[db_symbol] == 0
      @game_state.game_variables[Yuki::Var::Pokedex_Seen] = @seen
    end

    # Mark a Creature as captured
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    def mark_captured(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__
      return unless creature_unlocked?(db_symbol)

      unless @has_captured.include?(db_symbol)
        @has_captured << db_symbol
        @captured += 1
      end
      @game_state.game_variables[Yuki::Var::Pokedex_Catch] = @captured
    end

    # Unmark a Creature as captured
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    def unmark_captured(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return if db_symbol == :__undef__

      if @has_captured.include?(db_symbol)
        @has_captured.delete(db_symbol)
        @captured -= 1
      end
      @game_state.game_variables[Yuki::Var::Pokedex_Catch] = @captured
    end

    # Has the player seen a Creature
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @return [Boolean]
    def creature_seen?(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return false if db_symbol == :__undef__

      return @has_seen_and_forms[db_symbol] != 0
    end
    alias pokemon_seen? creature_seen?
    alias has_seen? creature_seen?

    # Has the player caught this Creature
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @return [Boolean]
    def creature_caught?(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return false if db_symbol == :__undef__

      return @has_captured.include?(db_symbol)
    end
    alias pokemon_caught? creature_caught?
    alias has_captured? creature_caught?

    # Get the seen forms informations of a Creature
    # @param db_symbol [Symbol] db_symbol of the Creature in the database
    # @return [Integer] An interger where int[form] == 1 mean the form has been seen
    def form_seen(db_symbol)
      db_symbol = data_creature(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return 0 if db_symbol == :__undef__

      return @has_seen_and_forms[db_symbol]
    end
    alias get_forms form_seen

    # Tell if the creature is unlocked in the current dex state
    # @param db_symbol [Symbol]
    # @return [Boolean]
    def creature_unlocked?(db_symbol)
      return true if national?

      return data_dex(@variant).creatures.any? { |creature| creature.db_symbol == db_symbol }
    end

    # Calibrate the Pokedex information (seen/captured)
    def calibrate
      @has_seen_and_forms.delete_if { |_, v| v == 0 }
      @seen = @has_seen_and_forms.size
      @captured = @has_captured.size
      @game_state.game_variables[Yuki::Var::Pokedex_Catch] = @captured
      @game_state.game_variables[Yuki::Var::Pokedex_Seen] = @seen
    end

    # Detect the best worldmap to display for the creature
    # @param db_symbol [Symbol] db_symbol of the creature we want the worldmap to display
    # @return [Integer]
    def best_worldmap_for_creature(db_symbol)
      default = @game_state.env.get_worldmap
      return default if each_data_world_map.size == 0

      zone_db_symbols = spawn_zones(db_symbol)
      return default if zone_db_symbols.empty?

      world_maps = zone_db_symbols.map { |zone_db_symbol| data_zone(zone_db_symbol).worldmaps }.flatten.compact
      return default if world_maps.empty?

      best_id = world_maps.group_by { |id| id }.map { |k, v| [k, v.size] }.max_by(&:last).first
      return best_id || default
    end
    alias best_worldmap_pokemon best_worldmap_for_creature

    # Return the list of the zone id where the creature spawns
    # @param db_symbol [Symbol] db_symbol of the creature we want to know where it spawns
    # @return [Array<Symbol>]
    def spawn_zones(db_symbol)
      # @type [Array<Studio::Zone>]
      zones = each_data_zone.select do |zone|
        # @type [Array<Studio::Group>]
        groups = zone.wild_groups.map { |group_db_symbol| data_group(group_db_symbol) }
        next groups.any? { |group| group.encounters.any? { |encounter| encounter.specie == db_symbol } }
      end
      return zones.map(&:db_symbol)
    end
  end

  class GameState
    # The Pokedex of the player
    # @return [PFM::Pokedex]
    attr_accessor :pokedex

    on_player_initialize(:pokedex) { @pokedex = PFM.dex_class.new(self) }
    on_expand_global_variables(:pokedex) do
      # Variable containing the Pokedex Information
      $pokedex = @pokedex
      @pokedex.game_state = self
      @pokedex.convert_to_dot26 if trainer.current_version < 6656
    end
  end
end

PFM.dex_class = PFM::Pokedex
