module Battle
  module Effects
    class CudChewEffect < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param counter [Integer] (default:2)
      # @param origin [PFM::PokemonBattler] Pokemon that used the move dealing this effect
      def initialize(logic, pokemon, counter, consumed_item)
        super(logic, pokemon)
        self.counter = counter
        @consumed_item = consumed_item
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return unless triggered?
        return unless battlers.include?(@pokemon)
        return if @pokemon.dead?

        scene.visual.show_ability(@pokemon)
        scene.visual.wait_for_animation
        user_effect = Effects::Item.new(logic, @pokemon, @consumed_item)
        user_effect.execute_berry_effect(force_heal: true, force_execution: true)
      end

      # If the effect can proc
      # @return [Boolean]
      def triggered?
        return @counter == 1
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :cud_chew_effect
      end
    end
  end
end
