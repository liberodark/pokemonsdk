module Battle
  module Effects
    class Telekinesis < PokemonTiedEffectBase
      include Mechanics::ForceFlying

      # Makes the grounded pokemon fly
      Mechanics::ForceFlying.register_force_flying_hook('PSDK flying: Telekinesis', :telekinesis)

      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param duration [Integer] (default: 3) duration of the move (including the current turn)
      def initialize(logic, pokemon, duration = 3)
        super(logic, pokemon)

        force_flying_initialize(pokemon, name, duration)
      end

      # Function called at the end of an action
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      # @note Specific interaction with Mega Gengar, we pass into this function just after activating the mega (which is an action)
      def on_post_action_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return if @pokemon.dead?
        return unless @pokemon.db_symbol == :gengar && @pokemon.form == 30

        kill
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        return :telekinesis
      end

      private

      # Message displayed when the effect wear off
      # @return [String]
      def on_delete_message
        parse_text_with_pokemon(19, 1149, @pokemon)
      end
    end
  end
end
