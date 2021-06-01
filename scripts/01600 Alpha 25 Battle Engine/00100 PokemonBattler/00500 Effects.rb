module PFM
  # Class defining a Pokemon during a battle, it aim to copy its properties but also to have the methods related to the battle.
  class PokemonBattler
    # Get the effect hanndler
    # @return [Battle::Effects::EffectsHandler]
    attr_reader :effects

    Hooks.register(PFM::PokemonBattler, :on_reset_states, 'PSDK reset effects') do
      @effects = Battle::Effects::EffectsHandler.new
    end

    # Get the status effect
    # @return [Battle::Effects::Status]
    def status_effect
      @status_effect = Battle::Effects::Status.new(@scene.logic, self, @status) if !@status_effect || @status_effect.status_id != @status
      return @status_effect
    end
  end
end
