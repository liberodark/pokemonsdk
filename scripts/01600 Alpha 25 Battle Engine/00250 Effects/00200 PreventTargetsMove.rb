module Battle::Effects
  class PreventTargetsMove < PokemonTiedEffectBase
    include Mechanics::WithTargets

    # Create a new effect
    # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
    def initialize(logic, user, targets, duration = 1)
      super(logic, user)
      initialize_with_targets(targets)
      self.counter = duration
    end

    # Function giving the name of the effect
    # @return [Symbol]
    def name
      :prevent_targets_move
    end
  end
end
