module Battle
  class Logic
    # Get a new stat change handler
    # @return [Battle::Logic::StatChangeHandler]
    def stat_change_handler
      return StatChangeHandler.new(self, @battle_scene)
    end

    # Get a new item change handler
    # @return [Battle::Logic::ItemChangeHandler]
    def item_change_handler
      return ItemChangeHandler.new(self, @battle_scene)
    end

    # Get a new item change handler
    # @return [Battle::Logic::StatusChangeHandler]
    def status_change_handler
      return StatusChangeHandler.new(self, @battle_scene)
    end

    # Get a new damage handler
    # @return [Battle::Logic::DamageHandler]
    def damage_handler
      return DamageHandler.new(self, @battle_scene)
    end

    # Get a new switch handler
    # @return [Battle::Logic::SwitchHandler]
    def switch_handler
      return SwitchHandler.new(self, @battle_scene)
    end

    # Get a new switch handler
    # @return [Battle::Logic::EndTurnHandler]
    def end_turn_handler
      return EndTurnHandler.new(self, @battle_scene)
    end

    # Get a new weather change handler
    # @return [Battle::Logic::WeatherChangeHandler]
    def weather_change_handler
      return WeatherChangeHandler.new(self, @battle_scene)
    end

    # Get the flee handler
    # @return [Battle::Logic::FleeHandler]
    def flee_handler
      return FleeHandler.new(self, @battle_scene)
    end
  end
end
