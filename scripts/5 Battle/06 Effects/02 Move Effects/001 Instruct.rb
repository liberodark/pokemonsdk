module Battle
  module Effects
    # Implement the Beak Blast effect
    class Instruct < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon)
        super
        self.counter = 1
      end

      # Function called at the end of an action
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_post_action_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return if @pokemon.dead?

        current_action = logic.current_action
        return unless current_action.is_a?(Actions::Attack) && current_action.launcher == @pokemon

        kill
        @pokemon.effects.delete_specific_dead_effect(:instruct)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :instruct
      end
    end
  end
end
