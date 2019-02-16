module PFM
  class PokemonBattler
    # @return [Array<Symbol>] List of the update method to call at the end of each turn
    END_TURN_UPDATE = []

    # Initialize the states of the Pokemon
    def init_states
      @confuse_count = 0
    end

    # Update all the status/effect at the end of a turn
    def update_status
      END_TURN_UPDATE.each { |method_name| send(method_name) }
    end

    # @return [Boolean] Is the Pokemon confused ?
    def confused?
      @confuse_count > 0
    end

    # Update the confuse state
    def update_confuse_count
      return unless confused?
      @confuse_count -= 1
      return if confused?
      # Display the message about the end of the confusion
    end
    END_TURN_UPDATE << :update_confuse_count
  end
end
